# HDiary-only 仓库裁剪 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把当前 iOS mono repo 裁剪成只保留 HDiary 可开发、可构建、可测试、可发布的项目仓库。

**Architecture:** 保留现有路径结构，不把 `MonoRepos/HDiary` 扁平化到根目录，避免 Xcode 和 SwiftPM 大规模路径改写。删除其他 app 的源码、网站、Pods 和专用发布脚本，并同步裁剪 workspace、CI、docs、网站入口和根目录构建配置。

**Tech Stack:** Xcode workspace、Swift/SwiftPM、Azure Pipelines、Nx/TypeScript CI helper、`npx skills` project skills、XcodeBuildMCP。

## Global Constraints

- 保留 `MonoRepos/HDiary/`、`HSharedCode/`、`websites/hdiary/`、HDiary 相关 CI/脚本/文档、`.agents/skills/` 和 `skills-lock.json`。
- 删除非 HDiary app：`MonoRepos/AppStoreArtWork`、`MonoRepos/ClipboardInspector`、`MonoRepos/ExifViewer`、`MonoRepos/HAgility`、`MonoRepos/HDoc`、`MonoRepos/Learn`、`MonoRepos/libai`、`MonoRepos/SharedCode`。
- 删除当前 `Pods/`、`Podfile`、`Podfile.lock`，因为现有 Podfile 只配置 HAgility。
- 不移动 `MonoRepos/HDiary` 到仓库根目录。
- 不重写 HDiary bundle id、signing、CloudKit、IAP 或 localization。
- 不提交任何更改，除非用户另行明确要求；每个任务用 review checkpoint 替代 commit。
- 所有联网命令必须 export 本地代理：`HTTP_PROXY=http://127.0.0.1:1082 HTTPS_PROXY=http://127.0.0.1:1082 ALL_PROXY=http://127.0.0.1:1082 http_proxy=http://127.0.0.1:1082 https_proxy=http://127.0.0.1:1082 all_proxy=http://127.0.0.1:1082 NO_PROXY=localhost,127.0.0.1,::1 no_proxy=localhost,127.0.0.1,::1`。

---

## File Structure

- Delete: `MonoRepos/AppStoreArtWork/`
- Delete: `MonoRepos/ClipboardInspector/`
- Delete: `MonoRepos/ExifViewer/`
- Delete: `MonoRepos/HAgility/`
- Delete: `MonoRepos/HDoc/`
- Delete: `MonoRepos/Learn/`
- Delete: `MonoRepos/libai/`
- Delete: `MonoRepos/SharedCode/`
- Delete: `websites/hdoc/`
- Delete: `Pods/`
- Delete: `Podfile`
- Delete: `Podfile.lock`
- Delete: `build/`
- Delete: `build_and_upload_testflight.sh`
- Delete: `docs/TESTFLIGHT_BUILD_GUIDE.md`
- Modify: `MonoProjects.xcworkspace/contents.xcworkspacedata` — only HDiary project and HSharedCode.
- Modify: `websites/index.html` — only links to HDiary.
- Modify: `README.md` — describe this as HDiary-only repo.
- Modify: `docs/how-to-release.md` — remove libai support URL and make wording HDiary-specific.
- Modify: `buildServer.json` — set scheme to `HDiary`.
- Modify: `build.xcconfig` — update HDoc comments to HDiary comments only.
- Modify: `azure-pipelines.yml` — only HDiary lint/build/test steps.
- Modify: `ci/src/lib/XcodeProject/ProjectName.ts` — remove non-HDiary project definitions.
- Modify: `ci/src/lib/XcodeProject/project-test.ts` — use `WORKSPACE_NAME` constant consistently.

---

### Task 1: 删除非 HDiary 内容

**Files:**
- Delete: `MonoRepos/AppStoreArtWork/`
- Delete: `MonoRepos/ClipboardInspector/`
- Delete: `MonoRepos/ExifViewer/`
- Delete: `MonoRepos/HAgility/`
- Delete: `MonoRepos/HDoc/`
- Delete: `MonoRepos/Learn/`
- Delete: `MonoRepos/libai/`
- Delete: `MonoRepos/SharedCode/`
- Delete: `websites/hdoc/`
- Delete: `Pods/`
- Delete: `Podfile`
- Delete: `Podfile.lock`
- Delete: `build/`
- Delete: `build_and_upload_testflight.sh`
- Delete: `docs/TESTFLIGHT_BUILD_GUIDE.md`

**Interfaces:**
- Consumes: approved spec `docs/superpowers/specs/2026-07-04-hdiary-only-repo-design.md`.
- Produces: a filesystem where only HDiary product directories and shared dependency roots remain.

- [ ] **Step 1: Inspect current top-level structure**

Run:

```bash
cd /Users/tigerguo/git/HHappyDocs
find MonoRepos -maxdepth 1 -mindepth 1 -type d | sort
find websites -maxdepth 1 -mindepth 1 -type d | sort
```

Expected: includes the directories listed in this task's delete list.

- [ ] **Step 2: Delete non-HDiary directories and files**

Run:

```bash
cd /Users/tigerguo/git/HHappyDocs
rm -rf \
  MonoRepos/AppStoreArtWork \
  MonoRepos/ClipboardInspector \
  MonoRepos/ExifViewer \
  MonoRepos/HAgility \
  MonoRepos/HDoc \
  MonoRepos/Learn \
  MonoRepos/libai \
  MonoRepos/SharedCode \
  websites/hdoc \
  Pods \
  Podfile \
  Podfile.lock \
  build \
  build_and_upload_testflight.sh \
  docs/TESTFLIGHT_BUILD_GUIDE.md
```

Expected: command exits 0.

- [ ] **Step 3: Verify retained product roots**

Run:

```bash
cd /Users/tigerguo/git/HHappyDocs
find MonoRepos -maxdepth 1 -mindepth 1 -type d | sort
find websites -maxdepth 1 -mindepth 1 -type d | sort
test -d MonoRepos/HDiary
test -d HSharedCode
test -d websites/hdiary
test -d .agents/skills
test -f skills-lock.json
```

Expected output:

```text
MonoRepos/HDiary
websites/hdiary
```

- [ ] **Step 4: Review checkpoint**

Run:

```bash
cd /Users/tigerguo/git/HHappyDocs
git --no-pager status --short -- MonoRepos websites Pods Podfile Podfile.lock build build_and_upload_testflight.sh docs/TESTFLIGHT_BUILD_GUIDE.md
```

Expected: deleted paths are shown as removed or absent; retained HDiary paths are not removed.

---

### Task 2: 改写 workspace、网站入口和根目录元数据

**Files:**
- Modify: `MonoProjects.xcworkspace/contents.xcworkspacedata`
- Modify: `websites/index.html`
- Modify: `README.md`
- Modify: `buildServer.json`
- Modify: `build.xcconfig`
- Modify: `docs/how-to-release.md`

**Interfaces:**
- Consumes: Task 1 retained `MonoRepos/HDiary`, `HSharedCode`, `websites/hdiary`.
- Produces: root metadata and website entry points that no longer reference non-HDiary apps.

- [ ] **Step 1: Replace Xcode workspace contents**

Set `MonoProjects.xcworkspace/contents.xcworkspacedata` to:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Workspace
   version = "1.0">
   <FileRef
      location = "group:HSharedCode">
   </FileRef>
   <FileRef
      location = "group:MonoRepos/HDiary/HDiary.xcodeproj">
   </FileRef>
</Workspace>
```

- [ ] **Step 2: Replace website index with HDiary-only links**

Set `websites/index.html` to:

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>HDiary</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 0;
            background-color: #f0f0f0;
        }
        .container {
            max-width: 800px;
            margin: auto;
            padding: 20px;
        }
        h1 {
            color: #333;
        }
        ul {
            list-style-type: none;
            padding: 0;
        }
        li {
            margin: 10px 0;
        }
        a {
            color: #007BFF;
            text-decoration: none;
        }
        a:hover {
            text-decoration: underline;
        }
        @media (max-width: 600px) {
            .container {
                padding: 10px;
            }
        }
    </style>
    <script>
        window.onload = function() {
            var userLang = navigator.language || navigator.userLanguage;
            var messageElement = document.getElementById('message');

            if (userLang.startsWith('zh')) {
                messageElement.innerHTML = `
                    <h1>快乐日记</h1>
                    <ul>
                        <li><a href="hdiary/index.html">快乐日记</a></li>
                    </ul>
                `;
            } else {
                messageElement.innerHTML = `
                    <h1>HDiary</h1>
                    <ul>
                        <li><a href="hdiary/index.html">HDiary</a></li>
                    </ul>
                `;
            }
        }
    </script>
</head>
<body>
    <div class="container" id="message"></div>
</body>
</html>
```

- [ ] **Step 3: Replace README**

Set `README.md` to:

```markdown
# HDiary

HDiary is an iOS app for recording happy moments.

## Project layout

- `MonoRepos/HDiary/` — app, widget, tests, release metadata, and `HDiaryLibrary`.
- `HSharedCode/` — shared Swift package used by `HDiaryLibrary`.
- `websites/hdiary/` — HDiary website and privacy policy.
- `ci/` and `scripts/` — project build and test helpers.
```

- [ ] **Step 4: Update build server metadata**

Set `buildServer.json` to:

```json
{
	"name": "xcode build server",
	"version": "0.2",
	"bspVersion": "2.0",
	"languages": [
		"c",
		"cpp",
		"objective-c",
		"objective-cpp",
		"swift"
	],
	"argv": [
		"/opt/homebrew/bin/xcode-build-server"
	],
	"workspace": "MonoProjects.xcworkspace",
	"build_root": "build",
	"scheme": "HDiary",
	"kind": "xcode"
}
```

- [ ] **Step 5: Update signing config comments**

Set `build.xcconfig` to:

```text
// HDiary TestFlight Build Configuration
// This file configures Xcode to use Automatic signing for Distribution.

CODE_SIGN_IDENTITY = Apple Distribution
CODE_SIGN_STYLE = Automatic
DEVELOPMENT_TEAM = F29WG8477A
// Let Xcode automatically manage provisioning profiles for distribution.
```

- [ ] **Step 6: Update release guide support URL**

Edit `docs/how-to-release.md` line 24 from:

```markdown
应该是 https://www.libaiapp.com
```

to:

```markdown
应该是 HDiary 的 support URL，例如 `websites/hdiary/index.html` 对应的线上地址。
```

- [ ] **Step 7: Verify no non-HDiary references in edited metadata**

Run:

```bash
cd /Users/tigerguo/git/HHappyDocs
rg -n "HDoc|HAgility|ClipboardInspector|ExifViewer|Learn|libai|hdoc" \
  MonoProjects.xcworkspace websites/index.html README.md buildServer.json build.xcconfig docs/how-to-release.md
```

Expected: no matches.

- [ ] **Step 8: Review checkpoint**

Run:

```bash
cd /Users/tigerguo/git/HHappyDocs
git --no-pager diff -- MonoProjects.xcworkspace/contents.xcworkspacedata websites/index.html README.md buildServer.json build.xcconfig docs/how-to-release.md
```

Expected: diff only contains HDiary-only metadata changes described above.

---

### Task 3: 裁剪 Azure Pipeline 和 TypeScript CI helper

**Files:**
- Modify: `azure-pipelines.yml`
- Modify: `ci/src/lib/XcodeProject/ProjectName.ts`
- Modify: `ci/src/lib/XcodeProject/project-test.ts`
- Verify: `ci/project.json`

**Interfaces:**
- Consumes: Task 2 workspace still named `MonoProjects.xcworkspace`, HDiary scheme still named `HDiary`.
- Produces: CI helper that only resolves HDiary, HSharedCode, and HDiaryLibrary projects.

- [ ] **Step 1: Replace Azure pipeline with HDiary-only pipeline**

Set `azure-pipelines.yml` to:

```yaml
# Xcode
# Build and test the HDiary Xcode workspace on macOS.

trigger:
  - main

pool:
  vmImage: "macOS-15"

stages:
  - stage: Check
    jobs:
      - job: Setup
        displayName: "Setup"
        steps:
          - script: |
              sudo xcode-select -s /Applications/Xcode_16.app && \
              xcodebuild -version && \
              xcrun simctl list
            displayName: "Check environment"

          - script: |
              make ios-lint-check
            displayName: "Lint HDiary"

          - task: NodeTool@0
            inputs:
              versionSpec: "20.x"
            displayName: "Install Node.js"

          - script: |
              make ios-build TARGET=HDiary
            displayName: "Build HDiary"

          - script: |
              make ios-test TARGET=HDiary
            displayName: "Test HDiary"
```

- [ ] **Step 2: Replace project registry with HDiary-only definitions**

Set `ci/src/lib/XcodeProject/ProjectName.ts` to:

```ts
export enum Platform {
    iOS = "iOS",
    macOS = "macOS",
    tvOS = "tvOS",
    watchOS = "watchOS"
}

export interface Project {
    // Name for project and file path for swift package.
    name: string;
    supportedPlatforms: Platform[];
    isSwiftPackage: boolean;
}

export const hDiary: Project = {
    name: "HDiary",
    supportedPlatforms: [Platform.iOS],
    isSwiftPackage: false
}

export const hSharedCode: Project = {
    name: "HSharedCode",
    supportedPlatforms: [Platform.iOS, Platform.macOS],
    isSwiftPackage: true
}

export const hSharedCodePackage: Project = {
    name: "HSharedCode-Package",
    supportedPlatforms: [Platform.iOS],
    isSwiftPackage: false
}

export const hDiaryLibrary: Project = {
    // This is a swift package's path.
    name: "MonoRepos/HDiary/HDiaryLibrary",
    supportedPlatforms: [Platform.iOS, Platform.macOS],
    isSwiftPackage: true,
}

// Declare a function that given a string, return specific project. The case is sensitive.
export function getProject(projectName: string): Project {
    switch (projectName) {
        case hDiary.name:
            return hDiary;
        case hSharedCode.name:
            return hSharedCode;
        case "HDiaryLibrary":
            return hDiaryLibrary;
        case hSharedCodePackage.name:
            return hSharedCodePackage;
        default:
            throw new Error(`Unknown project ${projectName}`);
    }
}
```

- [ ] **Step 3: Use shared workspace constant in project tests**

Change `ci/src/lib/XcodeProject/project-test.ts` imports from:

```ts
import { IOS_DESTINATION } from "../Constants/constants";
```

to:

```ts
import { IOS_DESTINATION, WORKSPACE_NAME } from "../Constants/constants";
```

Change:

```ts
const workspace = "MonoProjects";
```

to:

```ts
const workspace = WORKSPACE_NAME;
```

- [ ] **Step 4: Verify `ci/project.json` remains HDiary-only**

Run:

```bash
cd /Users/tigerguo/git/HHappyDocs
rg -n "HDoc|HAgility|ClipboardInspector|ExifViewer|Learn|Libai|libai" ci/project.json
```

Expected: no matches.

- [ ] **Step 5: Build CI helper**

Run:

```bash
cd /Users/tigerguo/git/HHappyDocs/ci
npm run build
```

Expected: Nx build exits 0 and emits `dist/ci`.

- [ ] **Step 6: Verify CI can resolve HDiary and reject deleted projects**

Run:

```bash
cd /Users/tigerguo/git/HHappyDocs/ci
node dist/ci/src/index.js test-command -r success
node - <<'NODE'
const { getProject } = require('./dist/ci/src/lib/XcodeProject/ProjectName');
console.log(getProject('HDiary').name);
try {
  getProject('HDoc');
  process.exit(1);
} catch (error) {
  console.log(String(error.message || error));
}
NODE
```

Expected output includes:

```text
success
HDiary
Unknown project HDoc
```

- [ ] **Step 7: Review checkpoint**

Run:

```bash
cd /Users/tigerguo/git/HHappyDocs
git --no-pager diff -- azure-pipelines.yml ci/src/lib/XcodeProject/ProjectName.ts ci/src/lib/XcodeProject/project-test.ts ci/project.json
```

Expected: pipeline and CI project registry contain only HDiary-related projects.

---

### Task 4: 验证 project skills 和清理临时安装产物

**Files:**
- Verify: `.agents/skills/`
- Verify: `skills-lock.json`
- Verify absent: `.codebuddy`

**Interfaces:**
- Consumes: installed project skills from previous work.
- Produces: confirmation that agent tooling survived repo pruning.

- [ ] **Step 1: List project skills**

Run:

```bash
cd /Users/tigerguo/git/HHappyDocs
export HTTP_PROXY=http://127.0.0.1:1082 HTTPS_PROXY=http://127.0.0.1:1082 ALL_PROXY=http://127.0.0.1:1082 http_proxy=http://127.0.0.1:1082 https_proxy=http://127.0.0.1:1082 all_proxy=http://127.0.0.1:1082 NO_PROXY=localhost,127.0.0.1,::1 no_proxy=localhost,127.0.0.1,::1
npx --yes skills list --json | node -e "let s=''; process.stdin.on('data', d=>s+=d); process.stdin.on('end',()=>{ const data=JSON.parse(s); const items=Array.isArray(data)?data:(data.skills||[]); console.log(items.length); for (const item of items) console.log(item.name || item.skill || item); });"
```

Expected output starts with:

```text
18
```

- [ ] **Step 2: Verify no temporary `.codebuddy` symlink remains**

Run:

```bash
cd /Users/tigerguo/git/HHappyDocs
test ! -e .codebuddy
```

Expected: exits 0.

- [ ] **Step 3: Verify installed skill files exist**

Run:

```bash
cd /Users/tigerguo/git/HHappyDocs
node - <<'NODE'
const fs = require('fs');
const lock = JSON.parse(fs.readFileSync('skills-lock.json', 'utf8'));
const names = Object.keys(lock.skills).sort();
const missing = names.filter(name => !fs.existsSync(`.agents/skills/${name}/SKILL.md`));
console.log(`skills-lock.json skills: ${names.length}`);
console.log(`missing: ${missing.length}`);
if (missing.length) {
  console.log(missing.join('\n'));
  process.exit(1);
}
NODE
```

Expected output:

```text
skills-lock.json skills: 18
missing: 0
```

- [ ] **Step 4: Review checkpoint**

Run:

```bash
cd /Users/tigerguo/git/HHappyDocs
git --no-pager status --short -- .agents skills-lock.json .codebuddy
```

Expected: `.agents/` and `skills-lock.json` are present; `.codebuddy` is absent.

---

### Task 5: 全仓库 HDiary-only 引用验证

**Files:**
- Verify: whole repository excluding intentionally historical planning docs.

**Interfaces:**
- Consumes: Tasks 1-4 cleanup.
- Produces: text-search proof that active files no longer reference removed apps.

- [ ] **Step 1: Verify removed app directories are gone**

Run:

```bash
cd /Users/tigerguo/git/HHappyDocs
for path in \
  MonoRepos/AppStoreArtWork \
  MonoRepos/ClipboardInspector \
  MonoRepos/ExifViewer \
  MonoRepos/HAgility \
  MonoRepos/HDoc \
  MonoRepos/Learn \
  MonoRepos/libai \
  MonoRepos/SharedCode \
  websites/hdoc \
  Pods \
  Podfile \
  Podfile.lock \
  build_and_upload_testflight.sh \
  docs/TESTFLIGHT_BUILD_GUIDE.md
do
  if [ -e "$path" ]; then
    echo "Still exists: $path"
    exit 1
  fi
done
echo "Removed app paths are absent"
```

Expected output:

```text
Removed app paths are absent
```

- [ ] **Step 2: Search active files for removed app references**

Run:

```bash
cd /Users/tigerguo/git/HHappyDocs
rg -n "HDoc|HAgility|ClipboardInspector|ExifViewer|Learn|Libai|libai|hdoc" \
  --glob '!docs/superpowers/**' \
  --glob '!**/.build/**' \
  --glob '!**/node_modules/**' \
  --glob '!**/.git/**'
```

Expected: no matches. If matches appear only in deleted-file diff metadata from git tooling, ignore the tooling output and inspect actual files with `rg`.

- [ ] **Step 3: Verify active HDiary references remain**

Run:

```bash
cd /Users/tigerguo/git/HHappyDocs
test -f MonoRepos/HDiary/HDiary.xcodeproj/project.pbxproj
test -f MonoRepos/HDiary/HDiaryLibrary/Package.swift
test -f HSharedCode/Package.swift
test -f websites/hdiary/index.html
test -f websites/hdiary/privacy.html
rg -n "HDiary" MonoProjects.xcworkspace azure-pipelines.yml ci/src README.md websites/index.html
```

Expected: exits 0 and shows HDiary references in active configuration files.

- [ ] **Step 4: Review checkpoint**

Run:

```bash
cd /Users/tigerguo/git/HHappyDocs
git --no-pager status --short
```

Expected: worktree shows the HDiary-only cleanup changes; no unexpected `.codebuddy` or temporary files.

---

### Task 6: Xcode scheme 和构建验证

**Files:**
- Verify: `MonoProjects.xcworkspace`
- Verify: `MonoRepos/HDiary/HDiary.xcodeproj`
- Verify: `HSharedCode/Package.swift`

**Interfaces:**
- Consumes: HDiary-only workspace and CI cleanup from previous tasks.
- Produces: build/test validation or a concrete blocker report.

- [ ] **Step 1: Configure XcodeBuildMCP defaults**

Use XcodeBuildMCP:

```text
xcodebuildmcp-session_show_defaults
xcodebuildmcp-session_set_defaults:
  workspacePath: /Users/tigerguo/git/HHappyDocs/MonoProjects.xcworkspace
  scheme: HDiary
  configuration: Debug
  simulatorName: iPhone 16
  simulatorPlatform: iOS Simulator
  useLatestOS: true
```

Expected: defaults point at `MonoProjects.xcworkspace` and scheme `HDiary`.

- [ ] **Step 2: List schemes**

Use XcodeBuildMCP:

```text
xcodebuildmcp-list_schemes:
  workspacePath: /Users/tigerguo/git/HHappyDocs/MonoProjects.xcworkspace
```

Expected: output includes `HDiary`. It must not include removed app schemes such as `HDoc`, `HAgility`, `ClipboardInspector`, `ExifViewer`, `Learn`, or `Libai`.

- [ ] **Step 3: Build HDiary for iOS Simulator**

Use XcodeBuildMCP:

```text
xcodebuildmcp-build_sim:
  extraArgs:
    - CODE_SIGN_IDENTITY=-
```

Expected: build succeeds. If it fails because simulator runtime, signing, package resolution, or local Xcode environment is missing, capture the first actionable error and stop instead of editing unrelated project settings.

- [ ] **Step 4: Run existing CI build command**

Run:

```bash
cd /Users/tigerguo/git/HHappyDocs
make ios-build TARGET=HDiary
```

Expected: CI helper builds HDiary or fails with the same actionable environment blocker as Step 3.

- [ ] **Step 5: Run existing CI test command**

Run:

```bash
cd /Users/tigerguo/git/HHappyDocs
make ios-test TARGET=HDiary
```

Expected: tests pass, or fail with a concrete environment blocker. Do not change signing, bundle identifiers, CloudKit, IAP, or localization settings to hide environment failures.

- [ ] **Step 6: Final review checkpoint**

Run:

```bash
cd /Users/tigerguo/git/HHappyDocs
git --no-pager diff --stat
git --no-pager status --short
```

Expected: diff contains only HDiary-only cleanup, project skill files, and the approved spec/plan docs. No commit is made unless the user explicitly asks.

---

## Self-Review

- Spec coverage: Tasks 1-2 cover filesystem pruning, website pruning, workspace metadata, README, build server, and release doc cleanup. Task 3 covers CI and scripts. Task 4 covers project skills. Task 5 covers active-reference cleanup. Task 6 covers XcodeBuildMCP build/test validation.
- Placeholder scan: no incomplete markers or vague implementation instructions remain.
- Type consistency: `getProject(projectName: string): Project`, `Project`, and `Platform` names match the existing TypeScript code. Workspace remains `MonoProjects.xcworkspace`; scheme remains `HDiary`.
