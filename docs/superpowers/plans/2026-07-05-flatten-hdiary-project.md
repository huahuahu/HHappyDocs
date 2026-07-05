# 扁平化 HDiary 项目实现计划

> **给 agentic workers：** 必须使用子技能：用 `superpowers:subagent-driven-development`（推荐）或 `superpowers:executing-plans` 按任务逐步实现本计划。步骤使用 checkbox（`- [ ]`）语法追踪。

**目标：** 删除根目录 Xcode workspace，把 HDiary app 从 `MonoRepos/HDiary/` 扁平化移动到仓库根目录，并改为只使用 GitHub Actions pipeline。

**架构：** 仓库变成单项目 HDiary checkout：`HDiary.xcodeproj` 位于根目录，app、测试、widget、package 文件夹与它同级；本地脚本和 CI 都改用 `-project HDiary.xcodeproj`，不再使用 `-workspace MonoProjects.xcworkspace`。`HSharedCode/` 继续作为根目录 Swift package 依赖保留，`HDiaryLibrary/Package.swift` 改用更短的同级相对路径引用它。

**技术栈：** Xcode project、Swift/SwiftPM、Swift packages、GitHub Actions、XcodeBuildMCP。

## 全局约束

- 只调整仓库结构和构建入口；不要重构 app 源码、测试、产品代码或 Swift package API。
- 本计划不删除或轮换本地密钥；`app-connect-upload-tf-private-key.p8` 保持由 `.gitignore` 忽略。
- 保留 `HDiary` 和 `HDiaryWidgetExtension` scheme 名称。
- 保留根目录 `HSharedCode/`；只更新依赖 `MonoRepos/HDiary/` 目录深度的引用。
- 删除作为活跃入口的 `MonoProjects.xcworkspace`，并在 HDiary 移出后删除 `MonoRepos/`。
- 删除旧 `azure-pipelines.yml` 和 `ci/` 目录；不要继续维护旧构建 helper。
- 新 CI 只创建 GitHub Actions workflow：`.github/workflows/ios.yml`。
- 检查旧路径活跃引用时排除 `docs/superpowers/` 下的历史计划/spec，因为新计划本身会记录旧路径。
- 任何 XcodeBuildMCP build/test/run 调用前，先调用 `xcodebuildmcp-session_show_defaults`；如果 defaults 仍指向 `MonoRepos/HDiary/HDiary.xcodeproj`，把 `projectPath` 改为根目录 `HDiary.xcodeproj` 的绝对路径。
- commit 步骤需要用户授权：只有用户在实现阶段明确授权 commit 时才创建 commit。

---

## 文件结构

- 移动：`MonoRepos/HDiary/HDiary.xcodeproj/` -> `HDiary.xcodeproj/`
- 移动：`MonoRepos/HDiary/HDiary/` -> `HDiary/`
- 移动：`MonoRepos/HDiary/HDiary.xctestplan` -> `HDiary.xctestplan`
- 移动：`MonoRepos/HDiary/HDiaryTests/` -> `HDiaryTests/`
- 移动：`MonoRepos/HDiary/HDiaryUITests/` -> `HDiaryUITests/`
- 移动：`MonoRepos/HDiary/HDiaryWidget/` -> `HDiaryWidget/`
- 移动：`MonoRepos/HDiary/HDiaryWidgetExtension.entitlements` -> `HDiaryWidgetExtension.entitlements`
- 移动：`MonoRepos/HDiary/HDiaryLibrary/` -> `HDiaryLibrary/`
- 移动：`MonoRepos/HDiary/IAP-doc/` -> `IAP-doc/`
- 移动：`MonoRepos/HDiary/PrivacyInfo.xcprivacy` -> `PrivacyInfo.xcprivacy`
- 移动：`MonoRepos/HDiary/release/` -> `release/`
- 删除：`MonoProjects.xcworkspace/`
- 删除：`MonoRepos/`（确认为空后）
- 删除：`azure-pipelines.yml`
- 删除：`ci/`
- 创建：`.github/workflows/ios.yml`
- 修改：`HDiaryLibrary/Package.swift` — 本地 package 路径从 `../../../HSharedCode` 改为 `../HSharedCode`。
- 修改：`HDiary.xcodeproj/xcshareddata/xcschemes/HDiary.xcscheme` — StoreKit 路径从 workspace 相对路径改为根目录 project 布局下的相对路径。
- 修改：`scripts/build-ios-project.sh` — 使用 `-project HDiary.xcodeproj`。
- 修改：`scripts/test-ios-project.sh` — 使用 `-project HDiary.xcodeproj`。
- 修改：`buildServer.json` — 使用 `project: "HDiary.xcodeproj"`，不再使用 `workspace`。
- 修改：`.xcodebuildmcp/config.yaml` — 根目录 project defaults。
- 修改：`README.md`、`docs/how-to-release.md` — 活跃文档说明根目录 project 布局和 GitHub Actions pipeline。

---

### 任务 1：扁平化文件系统布局

**文件：**
- 移动：`MonoRepos/HDiary/HDiary.xcodeproj/` -> `HDiary.xcodeproj/`
- 移动：`MonoRepos/HDiary/HDiary/` -> `HDiary/`
- 移动：`MonoRepos/HDiary/HDiary.xctestplan` -> `HDiary.xctestplan`
- 移动：`MonoRepos/HDiary/HDiaryTests/` -> `HDiaryTests/`
- 移动：`MonoRepos/HDiary/HDiaryUITests/` -> `HDiaryUITests/`
- 移动：`MonoRepos/HDiary/HDiaryWidget/` -> `HDiaryWidget/`
- 移动：`MonoRepos/HDiary/HDiaryWidgetExtension.entitlements` -> `HDiaryWidgetExtension.entitlements`
- 移动：`MonoRepos/HDiary/HDiaryLibrary/` -> `HDiaryLibrary/`
- 移动：`MonoRepos/HDiary/IAP-doc/` -> `IAP-doc/`
- 移动：`MonoRepos/HDiary/PrivacyInfo.xcprivacy` -> `PrivacyInfo.xcprivacy`
- 移动：`MonoRepos/HDiary/release/` -> `release/`
- 删除：`MonoProjects.xcworkspace/`
- 删除：`MonoRepos/`

**接口：**
- 消费：当前 `MonoRepos/HDiary/` 下的 HDiary 仓库布局。
- 产出：根目录下的 `HDiary.xcodeproj`、app/test/widget/package 文件夹，并且不再存在活跃的 `MonoProjects.xcworkspace` 或 `MonoRepos/` 目录。

- [ ] **步骤 1：确认工作区状态和目标路径**

运行：

```bash
git --no-pager status --short

for p in \
  HDiary.xcodeproj \
  HDiary \
  HDiary.xctestplan \
  HDiaryTests \
  HDiaryUITests \
  HDiaryWidget \
  HDiaryWidgetExtension.entitlements \
  HDiaryLibrary \
  IAP-doc \
  PrivacyInfo.xcprivacy \
  release
do
  test ! -e "$p" || { echo "destination exists: $p"; exit 1; }
done

test -d MonoRepos/HDiary
test -d MonoProjects.xcworkspace
find MonoRepos -maxdepth 1 -mindepth 1 -type d -print | sort
```

预期：

```text
MonoRepos/HDiary
```

如果 `git status --short` 显示用户已有改动，不要触碰它们；只要这些改动没有占用上面列出的目标路径，就可以继续。

- [ ] **步骤 2：把 HDiary project 文件移动到仓库根目录**

运行：

```bash
git mv MonoRepos/HDiary/HDiary.xcodeproj HDiary.xcodeproj
git mv MonoRepos/HDiary/HDiary HDiary
git mv MonoRepos/HDiary/HDiary.xctestplan HDiary.xctestplan
git mv MonoRepos/HDiary/HDiaryTests HDiaryTests
git mv MonoRepos/HDiary/HDiaryUITests HDiaryUITests
git mv MonoRepos/HDiary/HDiaryWidget HDiaryWidget
git mv MonoRepos/HDiary/HDiaryWidgetExtension.entitlements HDiaryWidgetExtension.entitlements
git mv MonoRepos/HDiary/HDiaryLibrary HDiaryLibrary
git mv MonoRepos/HDiary/IAP-doc IAP-doc
git mv MonoRepos/HDiary/PrivacyInfo.xcprivacy PrivacyInfo.xcprivacy
git mv MonoRepos/HDiary/release release
```

预期：每条命令退出码为 0，`git status --short` 显示从 `MonoRepos/HDiary/...` 到根目录路径的 rename。

- [ ] **步骤 3：删除根目录 workspace**

运行：

```bash
git rm -r MonoProjects.xcworkspace
rm -rf MonoProjects.xcworkspace
```

预期：tracked workspace 文件被 staged 为删除，未跟踪的 `xcuserdata` 残留从磁盘删除。

- [ ] **步骤 4：删除现在为空的 monorepo 目录**

运行：

```bash
find MonoRepos -maxdepth 3 -print | sort
rm -f MonoRepos/HDiary/.DS_Store MonoRepos/.DS_Store
rmdir MonoRepos/HDiary
rmdir MonoRepos
```

预期：`rmdir` 退出码为 0。如果 `find MonoRepos -maxdepth 3 -print` 列出 `MonoRepos`、`MonoRepos/HDiary` 和 `.DS_Store` 以外的任何内容，停止并检查，不要直接删除。

- [ ] **步骤 5：验证扁平化布局**

运行：

```bash
test -f HDiary.xcodeproj/project.pbxproj
test -d HDiary
test -f HDiary.xctestplan
test -d HDiaryTests
test -d HDiaryUITests
test -d HDiaryWidget
test -f HDiaryWidgetExtension.entitlements
test -f HDiaryLibrary/Package.swift
test -d IAP-doc
test -f PrivacyInfo.xcprivacy
test -d release
test ! -e MonoProjects.xcworkspace
test ! -e MonoRepos
```

预期：所有检查退出码为 0。

- [ ] **步骤 6：检查本任务 diff**

运行：

```bash
git --no-pager status --short
git --no-pager diff --stat
```

预期：diff stat 显示根目录 rename、`MonoProjects.xcworkspace` 删除，并且没有无关文件修改。

- [ ] **步骤 7：如果已授权，创建 checkpoint commit**

只有用户明确授权 commit 时才运行：

```bash
git add -A
git commit -m "chore: flatten hdiary project layout

Co-authored-by: Copilot App <223556219+Copilot@users.noreply.github.com>"
```

预期：commit 成功，并且只包含任务 1 的文件系统变更。

---

### 任务 2：修复移动后的 package 和 scheme 路径

**文件：**
- 修改：`HDiaryLibrary/Package.swift`
- 修改：`HDiary.xcodeproj/xcshareddata/xcschemes/HDiary.xcscheme`

**接口：**
- 消费：任务 1 产出的根目录 `HDiaryLibrary/`、`HDiary/` 和 `HDiary.xcodeproj/`。
- 产出：能在扁平化根目录布局下解析的本地 Swift package 路径和 StoreKit scheme 路径。

- [ ] **步骤 1：更新 HSharedCode package 路径**

在 `HDiaryLibrary/Package.swift` 中，把：

```swift
.package(name: "HSharedCode", path: "../../../HSharedCode"),
```

替换为：

```swift
.package(name: "HSharedCode", path: "../HSharedCode"),
```

- [ ] **步骤 2：更新 scheme 的 StoreKit 文件路径**

在 `HDiary.xcodeproj/xcshareddata/xcschemes/HDiary.xcscheme` 中，把：

```xml
      <StoreKitConfigurationFileReference
         identifier = "../MonoRepos/HDiary/HDiary/IAP/HDiary.storekit">
      </StoreKitConfigurationFileReference>
```

替换为：

```xml
      <StoreKitConfigurationFileReference
         identifier = "../HDiary/IAP/HDiary.storekit">
      </StoreKitConfigurationFileReference>
```

保持 test plan 引用不变：

```xml
            reference = "container:HDiary/HDiary.xctestplan"
```

- [ ] **步骤 3：确认 project 局部文件不再保留移动前路径引用**

运行：

```bash
rg -n 'MonoRepos/HDiary|MonoProjects\.xcworkspace|\.\./\.\./\.\./HSharedCode|\.\./MonoRepos' \
  HDiaryLibrary \
  HDiary.xcodeproj
```

预期：无输出。

- [ ] **步骤 4：验证 package manifest 能用新的本地依赖路径解析**

运行：

```bash
swift package --package-path HDiaryLibrary dump-package > /tmp/hdiarylibrary-package.json
```

预期：退出码为 0，且 `/tmp/hdiarylibrary-package.json` 包含 `"name" : "HDiaryLibrary"`。

- [ ] **步骤 5：检查本任务 diff**

运行：

```bash
git --no-pager diff -- HDiaryLibrary/Package.swift HDiary.xcodeproj/xcshareddata/xcschemes/HDiary.xcscheme
```

预期：只包含上面两个路径修改。

- [ ] **步骤 6：如果已授权，创建 checkpoint commit**

只有用户明确授权 commit 时才运行：

```bash
git add HDiaryLibrary/Package.swift HDiary.xcodeproj/xcshareddata/xcschemes/HDiary.xcscheme
git commit -m "chore: update hdiary root paths

Co-authored-by: Copilot App <223556219+Copilot@users.noreply.github.com>"
```

预期：commit 成功，并且只包含任务 2 的路径修改。

---

### 任务 3：把本地脚本从 workspace 切换到 project

**文件：**
- 修改：`scripts/build-ios-project.sh`
- 修改：`scripts/test-ios-project.sh`

**接口：**
- 消费：任务 1 产出的根目录 `HDiary.xcodeproj`。
- 产出：本地 build/test 脚本使用 `-project HDiary.xcodeproj` 调用 Xcode。

- [ ] **步骤 1：更新本地 build 脚本**

把 `scripts/build-ios-project.sh` 设置为：

```bash
function buildScheme {
    set -e

    scheme=$1
    onlyIOS=$2
    destinationIOS="\"platform=iOS Simulator,name=iPhone 15,OS=17.0\""
    destinationMac="'platform=macOS,arch=x86_64'"

    destination1="-destination $destinationIOS -destination $destinationMac"

    if [ "$onlyIOS" = "--only-ios" ]; then
        destination1="-destination $destinationIOS"
    fi

    project="HDiary.xcodeproj"
    command="xcodebuild -project $project"
    command="$command -scheme $scheme"
    command="$command -configuration Debug"
    command="$command $destination1"
    command="$command CODE_SIGN_IDENTITY=\"-\""
    command="$command build"
    echo $command

    eval $command
}
```

- [ ] **步骤 2：更新本地 test 脚本**

把 `scripts/test-ios-project.sh` 设置为：

```bash
function testScheme {
    set -e

    scheme=$1
    destinationIOS="platform=iOS Simulator,name=iPhone 14,OS=17.0"

    project="HDiary.xcodeproj"

    xcodebuild \
        clean \
        test \
        -project $project \
        -scheme $scheme \
        -configuration Debug \
        -destination "$destinationIOS" \
        CODE_SIGN_IDENTITY="-"
}
```

- [ ] **步骤 3：验证脚本不再提到 workspace**

运行：

```bash
rg -n 'MonoProjects\.xcworkspace|-workspace|workspace=' scripts
```

预期：无输出。

- [ ] **步骤 4：检查本任务 diff**

运行：

```bash
git --no-pager diff -- scripts/build-ios-project.sh scripts/test-ios-project.sh
```

预期：两个脚本都改为使用 `HDiary.xcodeproj`。

- [ ] **步骤 5：如果已授权，创建 checkpoint commit**

只有用户明确授权 commit 时才运行：

```bash
git add scripts/build-ios-project.sh scripts/test-ios-project.sh
git commit -m "chore: build hdiary with root xcode project

Co-authored-by: Copilot App <223556219+Copilot@users.noreply.github.com>"
```

预期：commit 成功，并且只包含任务 3 的脚本变更。

---

### 任务 4：删除旧 CI 并创建 GitHub Actions pipeline

**文件：**
- 删除：`azure-pipelines.yml`
- 删除：`ci/`
- 创建：`.github/workflows/ios.yml`

**接口：**
- 消费：任务 1 产出的根目录 `HDiary.xcodeproj` 和任务 3 的 project-based build/test 入口。
- 产出：仓库只保留 GitHub Actions pipeline 作为 CI 入口，不再保留旧 pipeline 文件或旧构建 helper。

- [ ] **步骤 1：删除旧 CI 文件和目录**

运行：

```bash
git rm azure-pipelines.yml
git rm -r ci
```

预期：`azure-pipelines.yml` 和 `ci/` 下的 tracked 文件都被 staged 为删除。

- [ ] **步骤 2：创建 GitHub Actions workflow**

创建 `.github/workflows/ios.yml`：

```yaml
name: iOS

on:
  push:
    branches:
      - main
  pull_request:

jobs:
  build-and-test:
    name: Build and test HDiary
    runs-on: macos-latest

    steps:
      - name: Check out repository
        uses: actions/checkout@v4

      - name: Select latest Xcode
        run: |
          latest_xcode="/Applications/Xcode.app"
          if [ ! -d "${latest_xcode}" ]; then
            latest_xcode="$(find /Applications -maxdepth 1 -type d -name 'Xcode*.app' | sort | tail -1)"
          fi
          echo "Using ${latest_xcode}"
          sudo xcode-select -s "${latest_xcode}/Contents/Developer"
          xcodebuild -version
          xcrun simctl list devices available

      - name: Build HDiary
        run: |
          xcodebuild \
            -project HDiary.xcodeproj \
            -scheme HDiary \
            -configuration Debug \
            -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
            CODE_SIGN_IDENTITY="-" \
            build

      - name: Test HDiary
        run: |
          xcodebuild \
            clean \
            test \
            -project HDiary.xcodeproj \
            -scheme HDiary \
            -configuration Debug \
            -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
            CODE_SIGN_IDENTITY="-"
```

- [ ] **步骤 3：验证 workflow 语法关键字段存在**

运行：

```bash
test -f .github/workflows/ios.yml
rg -n 'name: iOS|pull_request|runs-on: macos-latest|Select latest Xcode|-project HDiary\.xcodeproj|-scheme HDiary|iPhone 17 Pro' .github/workflows/ios.yml
```

预期：每个关键字段都有匹配输出。

- [ ] **步骤 4：验证旧 CI 入口已移除**

运行：

```bash
test ! -e azure-pipelines.yml
test ! -e ci
```

预期：所有检查退出码为 0。

- [ ] **步骤 5：检查本任务 diff**

运行：

```bash
git --no-pager diff --stat -- azure-pipelines.yml ci .github/workflows/ios.yml
git --no-pager diff -- .github/workflows/ios.yml
```

预期：旧 CI 删除，新增 `.github/workflows/ios.yml`，workflow 直接调用 `xcodebuild -project HDiary.xcodeproj`。

- [ ] **步骤 6：如果已授权，创建 checkpoint commit**

只有用户明确授权 commit 时才运行：

```bash
git add -A azure-pipelines.yml ci .github/workflows/ios.yml
git commit -m "ci: replace old pipeline with github actions

Co-authored-by: Copilot App <223556219+Copilot@users.noreply.github.com>"
```

预期：commit 成功，并且只包含任务 4 的 CI 替换变更。

---

### 任务 5：更新工具配置和活跃文档

**文件：**
- 修改：`buildServer.json`
- 修改：`.xcodebuildmcp/config.yaml`
- 修改：`README.md`
- 修改：`docs/how-to-release.md`

**接口：**
- 消费：任务 1 产出的根目录 `HDiary.xcodeproj` 和任务 4 的 GitHub Actions pipeline。
- 产出：editor/build-server defaults、XcodeBuildMCP defaults 和活跃文档都与扁平化布局一致。

- [ ] **步骤 1：更新 build server 配置**

把 `buildServer.json` 设置为：

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
	"project": "HDiary.xcodeproj",
	"build_root": "build",
	"scheme": "HDiary",
	"kind": "xcode"
}
```

- [ ] **步骤 2：更新 XcodeBuildMCP defaults**

在 `.xcodebuildmcp/config.yaml` 中，把：

```yaml
sessionDefaults:
  projectPath: MonoRepos/HDiary/HDiary.xcodeproj
  scheme: HDiary
```

替换为：

```yaml
sessionDefaults:
  projectPath: HDiary.xcodeproj
  scheme: HDiary
```

保留现有 simulator 字段不变。

- [ ] **步骤 3：更新 README project layout**

把 `README.md` 当前 `## Project layout` 小节替换为：

```markdown
## Project layout

- `HDiary.xcodeproj` — app、widget 和 tests 的根目录 Xcode project。
- `HDiary/` — HDiary app 源码、资源、StoreKit 配置和 app test plan。
- `HDiaryTests/` 和 `HDiaryUITests/` — unit tests 和 UI tests。
- `HDiaryWidget/` — widget extension 源码。
- `HDiaryLibrary/` — HDiary Swift package。
- `HSharedCode/` — `HDiaryLibrary` 使用的 shared Swift package。
- `release/` 和 `IAP-doc/` — release metadata 和 in-app purchase 支持文件。
- `websites/hdiary/` — HDiary website 和 privacy policy。
- `.github/workflows/ios.yml` — GitHub Actions build/test pipeline。
- `scripts/` — 本地 project build/test helper。
```

- [ ] **步骤 4：更新 release 文档路径措辞**

在 `docs/how-to-release.md` 中，把：

```markdown
## Update materials in appstore folder
```

替换为：

```markdown
## Update materials in `release/`
```

- [ ] **步骤 5：验证活跃文档/配置不再指向旧布局**

运行：

```bash
rg -n 'MonoProjects\.xcworkspace|MonoRepos/HDiary|MonoRepos|azure-pipelines|NodeTool|nx build' \
  README.md \
  docs/how-to-release.md \
  buildServer.json \
  .xcodebuildmcp/config.yaml \
  .github/workflows/ios.yml
```

预期：无输出。

- [ ] **步骤 6：检查本任务 diff**

运行：

```bash
git --no-pager diff -- buildServer.json .xcodebuildmcp/config.yaml README.md docs/how-to-release.md
```

预期：只包含本任务描述的配置和文档修改。

- [ ] **步骤 7：如果已授权，创建 checkpoint commit**

只有用户明确授权 commit 时才运行：

```bash
git add buildServer.json .xcodebuildmcp/config.yaml README.md docs/how-to-release.md
git commit -m "docs: document root hdiary project layout

Co-authored-by: Copilot App <223556219+Copilot@users.noreply.github.com>"
```

预期：commit 成功，并且只包含任务 5 的配置/文档变更。

---

### 任务 6：验证根目录 project、GitHub Actions pipeline 和活跃引用

**文件：**
- 验证：`HDiary.xcodeproj`
- 验证：`HDiaryLibrary/Package.swift`
- 验证：`.github/workflows/ios.yml`
- 验证：`docs/superpowers/` 外的活跃仓库文档/配置

**接口：**
- 消费：任务 1-5 全部完成。
- 产出：确认根目录 project 布局可用，只保留 GitHub Actions pipeline，没有活跃 workspace/monorepo/旧 CI 引用，并且 build/test cycle 使用 `HDiary.xcodeproj`。

- [ ] **步骤 1：build/test 前显示 XcodeBuildMCP defaults**

工具调用：

```text
xcodebuildmcp-session_show_defaults
```

预期：defaults 要么已经指向 `HDiary.xcodeproj`，要么显示旧的 `MonoRepos/HDiary/HDiary.xcodeproj` 路径，并需要在步骤 2 中替换。

- [ ] **步骤 2：把 XcodeBuildMCP defaults 设置为根目录 project**

工具调用：

```text
xcodebuildmcp-session_set_defaults({
  "projectPath": "/Users/tigerguo/git/HHappyDocs/HDiary.xcodeproj",
  "scheme": "HDiary",
  "simulatorId": "A044BA15-7770-48E6-8E28-E2123A772ACD",
  "simulatorName": "hdiary 17pro",
  "persist": true
})
```

预期：defaults 现在使用 `/Users/tigerguo/git/HHappyDocs/HDiary.xcodeproj` 和 scheme `HDiary`。

- [ ] **步骤 3：列出根目录 project schemes**

工具调用：

```text
xcodebuildmcp-list_schemes({
  "projectPath": "/Users/tigerguo/git/HHappyDocs/HDiary.xcodeproj"
})
```

预期：scheme 列表包含 `HDiary` 和 `HDiaryWidgetExtension`。

- [ ] **步骤 4：构建 simulator target**

工具调用：

```text
xcodebuildmcp-build_sim({})
```

预期：scheme `HDiary` 构建成功。

- [ ] **步骤 5：运行 simulator tests**

工具调用：

```text
xcodebuildmcp-test_sim({
  "progress": true
})
```

预期：test action 完成，并且没有 workspace 路径错误。如果 app tests 因为与移动无关的产品代码原因失败，记录失败 test 名称，并确认失败不是缺失 `MonoProjects.xcworkspace`、`MonoRepos/HDiary`、`HDiaryLibrary` 或 `HSharedCode` 路径导致。

- [ ] **步骤 6：验证活跃旧路径和旧 CI 引用已移除**

运行：

```bash
rg -n 'MonoProjects\.xcworkspace|MonoRepos/HDiary|MonoRepos|azure-pipelines|@nx/|@nrwl/|WORKSPACE_NAME|PROJECT_PATH' . \
  --glob '!docs/superpowers/**' \
  --glob '!**/.git/**' \
  --glob '!**/.build/**' \
  --glob '!venv/**'
```

预期：无输出。

- [ ] **步骤 7：验证期望的根目录文件存在，已删除目录不存在**

运行：

```bash
test -f HDiary.xcodeproj/project.pbxproj
test -d HDiary
test -d HDiaryLibrary
test -d HSharedCode
test -f .github/workflows/ios.yml
test ! -e MonoProjects.xcworkspace
test ! -e MonoRepos
test ! -e azure-pipelines.yml
test ! -e ci
```

预期：所有检查退出码为 0。

- [ ] **步骤 8：检查最终 diff**

运行：

```bash
git --no-pager status --short
git --no-pager diff --stat
git --no-pager diff --name-status
```

预期：变更仅限于本计划中的根目录布局移动/删除、路径/配置更新、GitHub Actions workflow 和活跃文档更新。

- [ ] **步骤 9：如果已授权，创建最终 checkpoint commit**

只有用户明确授权 commit，并且前面任务没有分别 commit 时才运行：

```bash
git add -A
git commit -m "chore: remove hdiary monorepo workspace

Co-authored-by: Copilot App <223556219+Copilot@users.noreply.github.com>"
```

预期：commit 成功，并包含完整根目录布局迁移。

---

## 自检

- Spec 覆盖：任务 1 删除根目录 workspace 并把 HDiary 移出 `MonoRepos`；任务 2 修复移动造成的路径变化；任务 3 把本地 build/test 脚本从 workspace 改为 project；任务 4 删除旧 CI 并创建 GitHub Actions workflow；任务 5 更新活跃配置/文档；任务 6 验证 schemes、build/test、文件布局、GitHub Actions pipeline 和活跃旧引用。
- 占位符检查：计划包含精确路径、替换片段、命令、预期输出和需要授权的 commit 命令；没有延后实现占位符。
- 类型一致性：计划不再维护旧 CI helper，因此没有 `WORKSPACE_NAME`、`PROJECT_PATH` 或 helper API 需要迁移；本地脚本和 GitHub Actions workflow 都直接使用 `HDiary.xcodeproj`。
