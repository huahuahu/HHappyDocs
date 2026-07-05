# Swift Package Product Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 `HDiary.xcodeproj` 直接编译的大部分 Swift 源码迁入现有 `HDiaryLibrary` Swift Package，并通过 package products 供 app、widget 和 tests 使用。

**Architecture:** 在 `HDiaryLibrary` 中新增 `HDiaryAppFeature` 与 `HDiaryWidgetFeature` library targets/products；Xcode app/widget targets 只保留最小 `@main` shim 并链接对应 product。Unit tests 迁入 package test target；UI tests 只迁移物理路径，仍由 Xcode UI test target 发现和运行。

**Tech Stack:** Swift 5.9、SwiftPM、Xcode project `PBXFileSystemSynchronizedRootGroup`、SwiftUI、WidgetKit、XCTest、XcodeBuildMCP。

## Global Constraints

- 只迁移 Swift 源码；`Info.plist`、entitlements、xcconfig、test plan、StoreKit、asset catalogs、AppIcon、app/widget `Localizable.xcstrings` 保留在 Xcode target 目录。
- 允许为真正 package product 迁移做必要 Swift 修改：`import`、`public`、`@main` shim、test import。
- 不做业务逻辑重写、UI 行为调整、资源模块化或大范围访问级别修改。
- 新增 app/widget feature targets 的主验证入口是 Xcode iOS Simulator build/test，不是 `swift test`。
- Xcode 相关验证使用 xcodebuildmcp；新 agent session 第一次 build/test 前必须先调用 `xcodebuildmcp-session_show_defaults`，如缺失则按 `.xcodebuildmcp/config.yaml` 设置 defaults。
- 如果 Xcode/SwiftPM 因 SwiftPM bare repository cache 报 `fatal: cannot use bare repository ... safe.bareRepository is 'explicit'`，只对失败命令使用一次性 `GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=safe.bareRepository GIT_CONFIG_VALUE_0=all`，不要改全局 Git config。

---

## File Structure

- `HDiaryLibrary/Package.swift`：新增 package dependencies、products 和 targets。
- `HDiaryLibrary/Sources/HDiaryAppFeature/**`：从 `HDiary/**/*.swift` 迁入的 app feature 源码；保留原相对目录结构。
- `HDiary/HDiaryApp.swift`：新增 app target shim，唯一留在 app target 中的 Swift entry。
- `HDiaryLibrary/Sources/HDiaryAppFeature/HDiaryApp.swift`：从原 app entry 迁入并改名为 package 公开入口 `HDiaryFeatureApp`。
- `HDiaryLibrary/Sources/HDiaryWidgetFeature/**`：从 `HDiaryWidget/**/*.swift` 迁入的 widget feature 源码；保留原相对目录结构。
- `HDiaryWidget/HDiaryWidgetBundle.swift`：新增 widget target shim，唯一留在 widget target 中的 Swift entry。
- `HDiaryLibrary/Sources/HDiaryWidgetFeature/HDiaryWidgetBundle.swift`：从原 widget entry 迁入并改名为 package 公开入口 `HDiaryWidgetFeatureBundle`。
- `HDiaryLibrary/Tests/HDiaryAppFeatureTests/**`：从 `HDiaryTests/**/*.swift` 迁入的 unit tests。
- `HDiaryLibrary/UITests/HDiaryUITests/**`：从 `HDiaryUITests/**/*.swift` 迁入的 UI tests；由 Xcode UI test target 编译。
- `HDiary.xcodeproj/project.pbxproj`：新增 app/widget package product dependencies；UI test synchronized root 指向迁移后的目录；移除 retired `HDiaryTests` target metadata。
- `HDiary/HDiary.xctestplan`：用 `HDiaryAppFeatureTests` package test target 替代 project-owned `HDiaryTests`。

---

### Task 1: Baseline 与迁移清单

**Files:**
- Modify: none
- Test: `HDiary` scheme build/test、`HDiaryWidgetExtension` scheme build

**Interfaces:**
- Consumes: 当前仓库状态和 `.xcodebuildmcp/config.yaml` 中的 defaults。
- Produces: 一组 baseline 命令输出，用来确认迁移前工程是可构建的，并记录 Swift 文件清单。

- [ ] **Step 1: 确认当前 git 状态只包含已批准的 planning 变更**

Run:

```bash
git --no-pager status --short
```

Expected: 只看到 `docs/superpowers/plans/2026-07-05-swift-package-product-migration.md` 未提交，或工作区干净；不能有未解释的 Swift/project 修改。

- [ ] **Step 2: 记录迁移前 Swift 文件清单**

Run:

```bash
git ls-files 'HDiary/**/*.swift' 'HDiary/*.swift' 'HDiaryWidget/**/*.swift' 'HDiaryTests/**/*.swift' 'HDiaryUITests/**/*.swift' | sort > /tmp/hdiary-swift-files-before.txt
wc -l /tmp/hdiary-swift-files-before.txt
sed -n '1,40p' /tmp/hdiary-swift-files-before.txt
```

Expected: 输出当前 project-owned Swift 文件数量；前 40 行包含 `HDiary/HDiaryApp.swift`、`HDiaryWidget/HDiaryWidgetBundle.swift`、`HDiaryTests/...` 和 `HDiaryUITests/...` 路径。

- [ ] **Step 3: 读取 XcodeBuildMCP defaults**

Tool: `xcodebuildmcp-session_show_defaults`

Expected: defaults 包含 `projectPath: HDiary.xcodeproj`、`scheme: HDiary`、`simulatorName: hdiary 17pro` 或可用 simulator id。

- [ ] **Step 4: 如果 defaults 缺失，按仓库配置设置 defaults**

Only if Step 3 缺失 project/scheme/simulator 信息，call:

```text
xcodebuildmcp-session_set_defaults(
  projectPath: "/Users/tigerguo/git/copilot-worktrees/HHappyDocs/huahuahu-vigilant-giggle/HDiary.xcodeproj",
  scheme: "HDiary",
  simulatorId: "A044BA15-7770-48E6-8E28-E2123A772ACD",
  simulatorName: "hdiary 17pro"
)
```

Expected: defaults 被设置为当前工程和 `HDiary` scheme。

- [ ] **Step 5: 运行迁移前 app build baseline**

Tool: `xcodebuildmcp-build_sim` with input:

```json
{
  "extraArgs": [
    "-configuration",
    "Debug",
    "CODE_SIGN_IDENTITY=-"
  ]
}
```

Expected: build succeeds。如果失败是 `safe.bareRepository`，按 Global Constraints 使用一次性 Git config override 重新跑同等 build；其他失败先记录并判断是否为已有 baseline 问题。

- [ ] **Step 6: 运行迁移前 app test baseline**

Tool: `xcodebuildmcp-test_sim` with input:

```json
{
  "extraArgs": [
    "-configuration",
    "Debug",
    "CODE_SIGN_IDENTITY=-"
  ],
  "progress": true
}
```

Expected: tests succeed，或记录明确 baseline failure。迁移任务只能修由迁移引入的问题。

- [ ] **Step 7: 运行迁移前 widget build baseline**

Tool: `xcodebuildmcp-session_set_defaults` with input:

```json
{
  "projectPath": "/Users/tigerguo/git/copilot-worktrees/HHappyDocs/huahuahu-vigilant-giggle/HDiary.xcodeproj",
  "scheme": "HDiaryWidgetExtension",
  "simulatorId": "A044BA15-7770-48E6-8E28-E2123A772ACD",
  "simulatorName": "hdiary 17pro"
}
```

Then call `xcodebuildmcp-build_sim` with input:

```json
{
  "extraArgs": [
    "-configuration",
    "Debug",
    "CODE_SIGN_IDENTITY=-"
  ]
}
```

Expected: widget build succeeds，或记录明确 baseline failure。

- [ ] **Step 8: Commit baseline-free checkpoint only if no code changed**

Run:

```bash
git --no-pager status --short
```

Expected: no source/project changes from baseline verification. 不提交。

---

### Task 2: App feature package target 迁移

**Files:**
- Modify: `HDiaryLibrary/Package.swift`
- Move: `HDiary/**/*.swift`, `HDiary/*.swift` -> `HDiaryLibrary/Sources/HDiaryAppFeature/...`
- Create: `HDiary/HDiaryApp.swift`
- Modify: `HDiaryLibrary/Sources/HDiaryAppFeature/HDiaryApp.swift`
- Modify: `HDiary.xcodeproj/project.pbxproj`
- Test: `HDiary` scheme build

**Interfaces:**
- Consumes: existing package products `HDiaryConstants`, `HDiaryModel`, `HDiarySearch`, `HDiaryIAP`, `HLocalization`, `HFoundation`, `HUIComponent`, `HMedia`; external product `SFSafeSymbols`.
- Produces: `public struct HDiaryFeatureApp: App` in module `HDiaryAppFeature`; `HDiary` Xcode target links product `HDiaryAppFeature`.

- [ ] **Step 1: Move app Swift files into package source target**

Run:

```bash
mkdir -p HDiaryLibrary/Sources/HDiaryAppFeature
while IFS= read -r file; do
  dest="HDiaryLibrary/Sources/HDiaryAppFeature/${file#HDiary/}"
  mkdir -p "$(dirname "$dest")"
  git mv "$file" "$dest"
done < <(git ls-files 'HDiary/**/*.swift' 'HDiary/*.swift' | sort)
```

Expected: all tracked Swift files under `HDiary/` move to `HDiaryLibrary/Sources/HDiaryAppFeature/` preserving relative paths; non-Swift resources remain under `HDiary/`.

- [ ] **Step 2: Convert moved app entry into package entry**

Apply this patch:

```diff
*** Begin Patch
*** Update File: HDiaryLibrary/Sources/HDiaryAppFeature/HDiaryApp.swift
@@
-@main
-struct HDiaryApp: App {
-  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
+public struct HDiaryFeatureApp: App {
+  @UIApplicationDelegateAdaptor(AppDelegate.self) private var delegate
+
+  public init() {}
 
-  var body: some Scene {
+  public var body: some Scene {
     WindowGroup {
       BaseTabView()
         .withEnvironments()
*** End Patch
```

Expected: `HDiaryLibrary/Sources/HDiaryAppFeature/HDiaryApp.swift` no longer contains `@main`; it exposes `HDiaryFeatureApp`.

- [ ] **Step 3: Create the app target shim**

Create `HDiary/HDiaryApp.swift` with:

```swift
import HDiaryAppFeature
import SwiftUI

@main
struct HDiaryApp: App {
  var body: some Scene {
    HDiaryFeatureApp().body
  }
}
```

Expected: `HDiary/` contains exactly one Swift entry file after this task.

- [ ] **Step 4: Add `HDiaryAppFeature` to `Package.swift` products**

Apply this patch:

```diff
*** Begin Patch
*** Update File: HDiaryLibrary/Package.swift
@@
     .library(
       name: "HDiaryIAP",
       targets: ["HDiaryIAP"]
     ),
+    .library(
+      name: "HDiaryAppFeature",
+      targets: ["HDiaryAppFeature"]
+    ),
 
   ],
*** End Patch
```

Expected: package exposes library product `HDiaryAppFeature`.

- [ ] **Step 5: Add `SFSafeSymbols` package dependency**

Apply this patch:

```diff
*** Begin Patch
*** Update File: HDiaryLibrary/Package.swift
@@
     .package(name: "HSharedCode", path: "../HSharedCode"),
     .package(url: "https://github.com/apple/swift-algorithms", from: "1.0.0"),
     .package(url: "https://github.com/apple/swift-atomics.git", from: "1.2.0"),
+    .package(url: "https://github.com/SFSafeSymbols/SFSafeSymbols", from: "6.2.0"),
   ],
*** End Patch
```

Expected: package can resolve the app feature's existing `import SFSafeSymbols` usages.

- [ ] **Step 6: Add `HDiaryAppFeature` target**

Apply this patch before the closing `]` of `targets` in `HDiaryLibrary/Package.swift`, after `HDiaryIAPTests`:

```diff
*** Begin Patch
*** Update File: HDiaryLibrary/Package.swift
@@
     .testTarget(
       name: "HDiaryIAPTests",
       dependencies: [
         "HDiaryIAP",
       ]
     ),
+    .target(
+      name: "HDiaryAppFeature",
+      dependencies: [
+        "HDiaryConstants",
+        "HDiaryIAP",
+        "HDiaryModel",
+        "HDiarySearch",
+        .product(name: "HFoundation", package: "HSharedCode"),
+        .product(name: "HLocalization", package: "HSharedCode"),
+        .product(name: "HMedia", package: "HSharedCode"),
+        .product(name: "HUIComponent", package: "HSharedCode"),
+        .product(name: "SFSafeSymbols", package: "SFSafeSymbols"),
+      ]
+    ),
   ]
 )
*** End Patch
```

Expected: `HDiaryAppFeature` target compiles moved app sources as a package module.

- [ ] **Step 7: Link `HDiaryAppFeature` in the Xcode app target**

Apply this patch to `HDiary.xcodeproj/project.pbxproj`:

```diff
*** Begin Patch
*** Update File: HDiary.xcodeproj/project.pbxproj
@@
 		601EEFB22B9D645E0073BA37 /* HDiaryIAP in Frameworks */ = {isa = PBXBuildFile; productRef = 601EEFB12B9D645E0073BA37 /* HDiaryIAP */; };
+		60F100102E00000100000001 /* HDiaryAppFeature in Frameworks */ = {isa = PBXBuildFile; productRef = 60F100112E00000100000001 /* HDiaryAppFeature */; };
 		60F100002E00000100000001 /* HDiarySearch in Frameworks */ = {isa = PBXBuildFile; productRef = 60F100012E00000100000001 /* HDiarySearch */; };
@@
 			files = (
+				60F100102E00000100000001 /* HDiaryAppFeature in Frameworks */,
 				601EEFB22B9D645E0073BA37 /* HDiaryIAP in Frameworks */,
 				60F100002E00000100000001 /* HDiarySearch in Frameworks */,
@@
 				601EEFAD2B9D3E0E0073BA37 /* HDiaryConstants */,
 				601EEFB12B9D645E0073BA37 /* HDiaryIAP */,
+				60F100112E00000100000001 /* HDiaryAppFeature */,
 				60E099272D93D3C800493EF6 /* SFSafeSymbols */,
@@
 		60F100012E00000100000001 /* HDiarySearch */ = {
 			isa = XCSwiftPackageProductDependency;
 			productName = HDiarySearch;
 		};
+		60F100112E00000100000001 /* HDiaryAppFeature */ = {
+			isa = XCSwiftPackageProductDependency;
+			productName = HDiaryAppFeature;
+		};
 		6050DD612B24331700CE3230 /* HMedia */ = {
*** End Patch
```

Expected: app target has a framework build file and product dependency for `HDiaryAppFeature`.

- [ ] **Step 8: Verify app target only has the shim Swift file in `HDiary/`**

Run:

```bash
find HDiary -name '*.swift' -print | sort
```

Expected:

```text
HDiary/HDiaryApp.swift
```

- [ ] **Step 9: Build app after app feature migration**

Tool: `xcodebuildmcp-session_set_defaults` with input:

```json
{
  "projectPath": "/Users/tigerguo/git/copilot-worktrees/HHappyDocs/huahuahu-vigilant-giggle/HDiary.xcodeproj",
  "scheme": "HDiary",
  "simulatorId": "A044BA15-7770-48E6-8E28-E2123A772ACD",
  "simulatorName": "hdiary 17pro"
}
```

Then call `xcodebuildmcp-build_sim` with input:

```json
{
  "extraArgs": [
    "-configuration",
    "Debug",
    "CODE_SIGN_IDENTITY=-"
  ]
}
```

Expected: build succeeds. If failures mention missing module dependencies, add only the missing `Package.swift` dependency. If failures mention access control for `HDiaryFeatureApp`, fix only `public init` or `public var body`.

- [ ] **Step 10: Review app migration diff and commit**

Run:

```bash
git --no-pager diff --summary
git --no-pager diff -- HDiaryLibrary/Package.swift HDiary.xcodeproj/project.pbxproj HDiary/HDiaryApp.swift HDiaryLibrary/Sources/HDiaryAppFeature/HDiaryApp.swift
git add HDiary HDiaryLibrary/Sources/HDiaryAppFeature HDiaryLibrary/Package.swift HDiary.xcodeproj/project.pbxproj
git commit -m "refactor: move app sources into package" -m "Co-authored-by: Copilot App <223556219+Copilot@users.noreply.github.com>"
```

Expected: moved Swift files show as renames where Git detects them; commit succeeds.

---

### Task 3: Widget feature package target 迁移

**Files:**
- Modify: `HDiaryLibrary/Package.swift`
- Move: `HDiaryWidget/**/*.swift` -> `HDiaryLibrary/Sources/HDiaryWidgetFeature/...`
- Create: `HDiaryWidget/HDiaryWidgetBundle.swift`
- Modify: `HDiaryLibrary/Sources/HDiaryWidgetFeature/HDiaryWidgetBundle.swift`
- Modify: `HDiary.xcodeproj/project.pbxproj`
- Test: `HDiaryWidgetExtension` scheme build

**Interfaces:**
- Consumes: existing package targets `HDiaryConstants` and `HDiaryModel`.
- Produces: `public struct HDiaryWidgetFeatureBundle: WidgetBundle` in module `HDiaryWidgetFeature`; widget Xcode target links product `HDiaryWidgetFeature`.

- [ ] **Step 1: Move widget Swift files into package source target**

Run:

```bash
mkdir -p HDiaryLibrary/Sources/HDiaryWidgetFeature
while IFS= read -r file; do
  dest="HDiaryLibrary/Sources/HDiaryWidgetFeature/${file#HDiaryWidget/}"
  mkdir -p "$(dirname "$dest")"
  git mv "$file" "$dest"
done < <(git ls-files 'HDiaryWidget/**/*.swift' 'HDiaryWidget/*.swift' | sort)
```

Expected: all tracked Swift files under `HDiaryWidget/` move to `HDiaryLibrary/Sources/HDiaryWidgetFeature/`; widget resources stay in `HDiaryWidget/`.

- [ ] **Step 2: Convert moved widget entry into package entry**

Apply this patch:

```diff
*** Begin Patch
*** Update File: HDiaryLibrary/Sources/HDiaryWidgetFeature/HDiaryWidgetBundle.swift
@@
-@main
-struct HDiaryWidgetBundle: WidgetBundle {
-  var body: some Widget {
+public struct HDiaryWidgetFeatureBundle: WidgetBundle {
+  public init() {}
+
+  public var body: some Widget {
     MomentWidget()
 //        HDiaryWidgetLiveActivity()
   }
 }
*** End Patch
```

Expected: moved widget bundle file no longer contains `@main`; it exposes `HDiaryWidgetFeatureBundle`.

- [ ] **Step 3: Create widget target shim**

Create `HDiaryWidget/HDiaryWidgetBundle.swift` with:

```swift
import HDiaryWidgetFeature
import WidgetKit

@main
struct HDiaryWidgetBundle: WidgetBundle {
  var body: some Widget {
    HDiaryWidgetFeatureBundle().body
  }
}
```

Expected: `HDiaryWidget/` contains exactly one Swift entry file after this task.

- [ ] **Step 4: Add `HDiaryWidgetFeature` product and target**

Apply this patch:

```diff
*** Begin Patch
*** Update File: HDiaryLibrary/Package.swift
@@
     .library(
       name: "HDiaryAppFeature",
       targets: ["HDiaryAppFeature"]
     ),
+    .library(
+      name: "HDiaryWidgetFeature",
+      targets: ["HDiaryWidgetFeature"]
+    ),
 
   ],
@@
     .target(
       name: "HDiaryAppFeature",
       dependencies: [
@@
         .product(name: "SFSafeSymbols", package: "SFSafeSymbols"),
       ]
     ),
+    .target(
+      name: "HDiaryWidgetFeature",
+      dependencies: [
+        "HDiaryConstants",
+        "HDiaryModel",
+      ]
+    ),
   ]
 )
*** End Patch
```

Expected: package exposes library product `HDiaryWidgetFeature`.

- [ ] **Step 5: Link `HDiaryWidgetFeature` in widget target**

Apply this patch to `HDiary.xcodeproj/project.pbxproj`:

```diff
*** Begin Patch
*** Update File: HDiary.xcodeproj/project.pbxproj
@@
 		601EEFB02B9D3E1B0073BA37 /* HDiaryConstants in Frameworks */ = {isa = PBXBuildFile; productRef = 601EEFAF2B9D3E1B0073BA37 /* HDiaryConstants */; };
+		60F100122E00000100000001 /* HDiaryWidgetFeature in Frameworks */ = {isa = PBXBuildFile; productRef = 60F100132E00000100000001 /* HDiaryWidgetFeature */; };
 		601EEFB22B9D645E0073BA37 /* HDiaryIAP in Frameworks */ = {isa = PBXBuildFile; productRef = 601EEFB12B9D645E0073BA37 /* HDiaryIAP */; };
@@
 			files = (
+				60F100122E00000100000001 /* HDiaryWidgetFeature in Frameworks */,
 				60E380222A62666300F32E2C /* HDiaryModel in Frameworks */,
@@
 				60E380212A62666300F32E2C /* HDiaryModel */,
 				601EEFAF2B9D3E1B0073BA37 /* HDiaryConstants */,
+				60F100132E00000100000001 /* HDiaryWidgetFeature */,
 			);
@@
 		60F100112E00000100000001 /* HDiaryAppFeature */ = {
 			isa = XCSwiftPackageProductDependency;
 			productName = HDiaryAppFeature;
 		};
+		60F100132E00000100000001 /* HDiaryWidgetFeature */ = {
+			isa = XCSwiftPackageProductDependency;
+			productName = HDiaryWidgetFeature;
+		};
 		6050DD612B24331700CE3230 /* HMedia */ = {
*** End Patch
```

Expected: widget target has a framework build file and product dependency for `HDiaryWidgetFeature`.

- [ ] **Step 6: Verify widget target only has the shim Swift file in `HDiaryWidget/`**

Run:

```bash
find HDiaryWidget -name '*.swift' -print | sort
```

Expected:

```text
HDiaryWidget/HDiaryWidgetBundle.swift
```

- [ ] **Step 7: Build widget after widget feature migration**

Tool: `xcodebuildmcp-session_set_defaults` with input:

```json
{
  "projectPath": "/Users/tigerguo/git/copilot-worktrees/HHappyDocs/huahuahu-vigilant-giggle/HDiary.xcodeproj",
  "scheme": "HDiaryWidgetExtension",
  "simulatorId": "A044BA15-7770-48E6-8E28-E2123A772ACD",
  "simulatorName": "hdiary 17pro"
}
```

Then call `xcodebuildmcp-build_sim` with input:

```json
{
  "extraArgs": [
    "-configuration",
    "Debug",
    "CODE_SIGN_IDENTITY=-"
  ]
}
```

Expected: widget build succeeds. If failures mention access control for `HDiaryWidgetFeatureBundle`, fix only `public init` or `public var body`.

- [ ] **Step 8: Review widget migration diff and commit**

Run:

```bash
git --no-pager diff --summary
git add HDiaryWidget HDiaryLibrary/Sources/HDiaryWidgetFeature HDiaryLibrary/Package.swift HDiary.xcodeproj/project.pbxproj
git commit -m "refactor: move widget sources into package" -m "Co-authored-by: Copilot App <223556219+Copilot@users.noreply.github.com>"
```

Expected: widget Swift files show as renames where Git detects them; commit succeeds.

---

### Task 4: Unit tests package 迁移

**Files:**
- Modify: `HDiaryLibrary/Package.swift`
- Move: `HDiaryTests/**/*.swift` -> `HDiaryLibrary/Tests/HDiaryAppFeatureTests/...`
- Modify: `HDiaryLibrary/Tests/HDiaryAppFeatureTests/AllTagsViewTests.swift`
- Modify: `HDiary/HDiary.xctestplan`
- Modify: `HDiary.xcodeproj/project.pbxproj`
- Test: `HDiary` scheme test

**Interfaces:**
- Consumes: `HDiaryAppFeature` target from Task 2.
- Produces: package test target `HDiaryAppFeatureTests` with `@testable import HDiaryAppFeature`; `HDiary/HDiary.xctestplan` references this package test target.

- [ ] **Step 1: Move unit test Swift files into package tests**

Run:

```bash
mkdir -p HDiaryLibrary/Tests/HDiaryAppFeatureTests
while IFS= read -r file; do
  dest="HDiaryLibrary/Tests/HDiaryAppFeatureTests/${file#HDiaryTests/}"
  mkdir -p "$(dirname "$dest")"
  git mv "$file" "$dest"
done < <(git ls-files 'HDiaryTests/**/*.swift' 'HDiaryTests/*.swift' | sort)
```

Expected: all tracked Swift files under `HDiaryTests/` move to `HDiaryLibrary/Tests/HDiaryAppFeatureTests/`.

- [ ] **Step 2: Update migrated test import**

Apply this patch:

```diff
*** Begin Patch
*** Update File: HDiaryLibrary/Tests/HDiaryAppFeatureTests/AllTagsViewTests.swift
@@
 import XCTest
-@testable import HDiary
+@testable import HDiaryAppFeature
*** End Patch
```

Expected: no unit test imports project module `HDiary`.

- [ ] **Step 3: Add package test target**

Apply this patch to `HDiaryLibrary/Package.swift`:

```diff
*** Begin Patch
*** Update File: HDiaryLibrary/Package.swift
@@
     .target(
       name: "HDiaryWidgetFeature",
       dependencies: [
         "HDiaryConstants",
         "HDiaryModel",
       ]
     ),
+    .testTarget(
+      name: "HDiaryAppFeatureTests",
+      dependencies: [
+        "HDiaryAppFeature",
+      ]
+    ),
   ]
 )
*** End Patch
```

Expected: package test target exists and depends on `HDiaryAppFeature`.

- [ ] **Step 4: Update Xcode test plan to reference package tests**

Apply this patch:

```diff
*** Begin Patch
*** Update File: HDiary/HDiary.xctestplan
@@
       "target": {
-        "containerPath": "container:HDiary.xcodeproj",
-        "identifier": "60A4E20F2A3DDCE3000E68A0",
-        "name": "HDiaryTests"
+        "containerPath": "container:HDiaryLibrary",
+        "identifier": "HDiaryAppFeatureTests",
+        "name": "HDiaryAppFeatureTests"
       }
*** End Patch
```

Expected: the first `testTargets` item points to `container:HDiaryLibrary` and `HDiaryAppFeatureTests`.

- [ ] **Step 5: Remove retired `HDiaryTests` Xcode target metadata**

Run this deterministic cleanup script:

```bash
python3 <<'PY'
from pathlib import Path

path = Path("HDiary.xcodeproj/project.pbxproj")
lines = path.read_text().splitlines(keepends=True)

block_markers = [
    "60A4E20F2A3DDCE3000E68A0 /* HDiaryTests */ = {",
    "60A4E20C2A3DDCE3000E68A0 /* Sources */ = {",
    "60A4E20D2A3DDCE3000E68A0 /* Frameworks */ = {",
    "60A4E20E2A3DDCE3000E68A0 /* Resources */ = {",
    "60A4E2112A3DDCE3000E68A0 /* PBXContainerItemProxy */ = {",
    "60A4E2122A3DDCE3000E68A0 /* PBXTargetDependency */ = {",
    "60A4E2272A3DDCE3000E68A0 /* Build configuration list for PBXNativeTarget \"HDiaryTests\" */ = {",
    "60A4E2282A3DDCE3000E68A0 /* Debug */ = {",
    "60A4E2292A3DDCE3000E68A0 /* Release */ = {",
    "60A4E20F2A3DDCE3000E68A0 = {",
]

line_markers = [
    "60A4E2102A3DDCE3000E68A0 /* HDiaryTests.xctest */ = {",
    "60F3DD262CDDF1C000C05BFB /* HDiaryTests */ = {",
    "60F3DD232CDDF1C000C05BFB /* PBXFileSystemSynchronizedBuildFileExceptionSet */ = {",
    "60A4E2102A3DDCE3000E68A0 /* HDiaryTests.xctest */,",
    "60F3DD262CDDF1C000C05BFB /* HDiaryTests */,",
    "60A4E20F2A3DDCE3000E68A0 /* HDiaryTests */,",
    "60A4E2122A3DDCE3000E68A0 /* PBXTargetDependency */,",
]

def remove_block(start_index: int) -> int:
    depth = 0
    for index in range(start_index, len(lines)):
        depth += lines[index].count("{")
        depth -= lines[index].count("}")
        if index > start_index and depth <= 0 and lines[index].lstrip().startswith("};"):
            return index + 1
    raise RuntimeError(f"Could not find block end for: {lines[start_index].strip()}")

out = []
index = 0
while index < len(lines):
    line = lines[index]
    if any(marker in line for marker in block_markers):
        index = remove_block(index)
        continue
    if any(marker in line for marker in line_markers):
        index += 1
        continue
    out.append(line)
    index += 1

path.write_text("".join(out))
PY
```

The script removes only these IDs and list entries from `HDiary.xcodeproj/project.pbxproj`:

```text
60A4E20F2A3DDCE3000E68A0 /* HDiaryTests */              PBXNativeTarget
60A4E2102A3DDCE3000E68A0 /* HDiaryTests.xctest */        PBXFileReference and Products child
60A4E20C2A3DDCE3000E68A0 /* Sources */                  PBXSourcesBuildPhase
60A4E20D2A3DDCE3000E68A0 /* Frameworks */               PBXFrameworksBuildPhase
60A4E20E2A3DDCE3000E68A0 /* Resources */                PBXResourcesBuildPhase
60A4E2112A3DDCE3000E68A0 /* PBXContainerItemProxy */     PBXContainerItemProxy
60A4E2122A3DDCE3000E68A0 /* PBXTargetDependency */       PBXTargetDependency
60A4E2272A3DDCE3000E68A0                                XCConfigurationList
60A4E2282A3DDCE3000E68A0                                XCBuildConfiguration Debug
60A4E2292A3DDCE3000E68A0                                XCBuildConfiguration Release
60F3DD262CDDF1C000C05BFB /* HDiaryTests */              PBXFileSystemSynchronizedRootGroup and main group child
60F3DD232CDDF1C000C05BFB                                PBXFileSystemSynchronizedBuildFileExceptionSet for HDiaryTests
60A4E20F2A3DDCE3000E68A0 in Project TargetAttributes
60A4E20F2A3DDCE3000E68A0 in Project targets
```

Expected after cleanup:

```bash
rg 'HDiaryTests|60A4E20F2A3DDCE3000E68A0|60F3DD262CDDF1C000C05BFB|60F3DD232CDDF1C000C05BFB' HDiary.xcodeproj/project.pbxproj
```

prints no matches.

- [ ] **Step 6: Remove empty `HDiaryTests` directory if present**

Run:

```bash
if [ -d HDiaryTests ]; then
  find HDiaryTests -type f -print
  rmdir HDiaryTests
else
  echo "HDiaryTests directory already absent"
fi
```

Expected: `HDiaryTests` no longer exists, or it was already absent.

- [ ] **Step 7: Run app scheme tests with package unit tests**

Tool: `xcodebuildmcp-session_set_defaults` with input:

```json
{
  "projectPath": "/Users/tigerguo/git/copilot-worktrees/HHappyDocs/huahuahu-vigilant-giggle/HDiary.xcodeproj",
  "scheme": "HDiary",
  "simulatorId": "A044BA15-7770-48E6-8E28-E2123A772ACD",
  "simulatorName": "hdiary 17pro"
}
```

Then call `xcodebuildmcp-test_sim` with input:

```json
{
  "extraArgs": [
    "-configuration",
    "Debug",
    "CODE_SIGN_IDENTITY=-"
  ],
  "progress": true
}
```

Expected: test plan discovers `HDiaryAppFeatureTests` from `container:HDiaryLibrary` and existing package tests; tests pass or match baseline failures from Task 1.

- [ ] **Step 8: Review unit test migration diff and commit**

Run:

```bash
git --no-pager diff --summary
git add HDiaryLibrary/Tests/HDiaryAppFeatureTests HDiaryLibrary/Package.swift HDiary/HDiary.xctestplan HDiary.xcodeproj/project.pbxproj
git add -u HDiaryTests
git commit -m "refactor: move app unit tests into package" -m "Co-authored-by: Copilot App <223556219+Copilot@users.noreply.github.com>"
```

Expected: unit test files show as moved; retired project target metadata is gone; commit succeeds.

---

### Task 5: UI test physical path 迁移

**Files:**
- Move: `HDiaryUITests/**/*.swift` -> `HDiaryLibrary/UITests/HDiaryUITests/...`
- Modify: `HDiary.xcodeproj/project.pbxproj`
- Test: `HDiary` scheme test

**Interfaces:**
- Consumes: existing Xcode UI test target `HDiaryUITests`.
- Produces: `HDiaryUITests` Xcode target still exists and compiles sources from `HDiaryLibrary/UITests/HDiaryUITests`.

- [ ] **Step 1: Move UI test Swift files into package-owned directory**

Run:

```bash
mkdir -p HDiaryLibrary/UITests/HDiaryUITests
while IFS= read -r file; do
  dest="HDiaryLibrary/UITests/HDiaryUITests/${file#HDiaryUITests/}"
  mkdir -p "$(dirname "$dest")"
  git mv "$file" "$dest"
done < <(git ls-files 'HDiaryUITests/**/*.swift' 'HDiaryUITests/*.swift' | sort)
```

Expected: all tracked Swift files under `HDiaryUITests/` move to `HDiaryLibrary/UITests/HDiaryUITests/`.

- [ ] **Step 2: Point Xcode UI test synchronized root to migrated path**

Apply this patch:

```diff
*** Begin Patch
*** Update File: HDiary.xcodeproj/project.pbxproj
@@
-		60F3DD2A2CDDF1C800C05BFB /* HDiaryUITests */ = {isa = PBXFileSystemSynchronizedRootGroup; explicitFileTypes = {}; explicitFolders = (); path = HDiaryUITests; sourceTree = "<group>"; };
+		60F3DD2A2CDDF1C800C05BFB /* HDiaryUITests */ = {isa = PBXFileSystemSynchronizedRootGroup; explicitFileTypes = {}; explicitFolders = (); path = HDiaryLibrary/UITests/HDiaryUITests; sourceTree = "<group>"; };
*** End Patch
```

Expected: project target name remains `HDiaryUITests`, but source root points to the migrated directory.

- [ ] **Step 3: Remove empty `HDiaryUITests` directory if present**

Run:

```bash
if [ -d HDiaryUITests ]; then
  find HDiaryUITests -type f -print
  rmdir HDiaryUITests
else
  echo "HDiaryUITests directory already absent"
fi
```

Expected: `HDiaryUITests` no longer exists, or it was already absent.

- [ ] **Step 4: Run app scheme tests with UI tests still project-owned**

Tool: `xcodebuildmcp-session_set_defaults` with input:

```json
{
  "projectPath": "/Users/tigerguo/git/copilot-worktrees/HHappyDocs/huahuahu-vigilant-giggle/HDiary.xcodeproj",
  "scheme": "HDiary",
  "simulatorId": "A044BA15-7770-48E6-8E28-E2123A772ACD",
  "simulatorName": "hdiary 17pro"
}
```

Then call `xcodebuildmcp-test_sim` with input:

```json
{
  "extraArgs": [
    "-configuration",
    "Debug",
    "CODE_SIGN_IDENTITY=-"
  ],
  "progress": true
}
```

Expected: `HDiaryUITests` target is discovered and compiled from `HDiaryLibrary/UITests/HDiaryUITests`; tests pass or match baseline failures from Task 1.

- [ ] **Step 5: Review UI test migration diff and commit**

Run:

```bash
git --no-pager diff --summary
git add HDiaryLibrary/UITests/HDiaryUITests HDiary.xcodeproj/project.pbxproj
git add -u HDiaryUITests
git commit -m "refactor: move ui tests under package tree" -m "Co-authored-by: Copilot App <223556219+Copilot@users.noreply.github.com>"
```

Expected: UI test files show as moved; `HDiaryUITests` Xcode target remains in project; commit succeeds.

---

### Task 6: Final verification and rename audit

**Files:**
- Modify: none unless verification exposes migration-only fixes
- Test: app build/test, widget build, diff rename audit

**Interfaces:**
- Consumes: completed app/widget/unit/UI migration commits.
- Produces: verified branch where project direct Swift sources are limited to app/widget shims and package-owned UI test exception.

- [ ] **Step 1: Verify remaining project-owned Swift files**

Run:

```bash
printf '%s\n' '--- HDiary ---'
find HDiary -name '*.swift' -print | sort
printf '%s\n' '--- HDiaryWidget ---'
find HDiaryWidget -name '*.swift' -print | sort
printf '%s\n' '--- HDiaryTests ---'
if [ -d HDiaryTests ]; then find HDiaryTests -name '*.swift' -print | sort; fi
printf '%s\n' '--- HDiaryUITests ---'
if [ -d HDiaryUITests ]; then find HDiaryUITests -name '*.swift' -print | sort; fi
```

Expected:

```text
--- HDiary ---
HDiary/HDiaryApp.swift
--- HDiaryWidget ---
HDiaryWidget/HDiaryWidgetBundle.swift
--- HDiaryTests ---
--- HDiaryUITests ---
```

- [ ] **Step 2: Verify migrated Swift files exist under package tree**

Run:

```bash
find HDiaryLibrary/Sources/HDiaryAppFeature -name '*.swift' | wc -l
find HDiaryLibrary/Sources/HDiaryWidgetFeature -name '*.swift' | wc -l
find HDiaryLibrary/Tests/HDiaryAppFeatureTests -name '*.swift' | wc -l
find HDiaryLibrary/UITests/HDiaryUITests -name '*.swift' | wc -l
```

Expected: counts correspond to the moved app, widget, unit test, and UI test files recorded in Task 1, minus the two new shims that remain under Xcode target directories.

- [ ] **Step 3: Run final app build**

Tool: `xcodebuildmcp-session_set_defaults` with input:

```json
{
  "projectPath": "/Users/tigerguo/git/copilot-worktrees/HHappyDocs/huahuahu-vigilant-giggle/HDiary.xcodeproj",
  "scheme": "HDiary",
  "simulatorId": "A044BA15-7770-48E6-8E28-E2123A772ACD",
  "simulatorName": "hdiary 17pro"
}
```

Then call `xcodebuildmcp-build_sim` with input:

```json
{
  "extraArgs": [
    "-configuration",
    "Debug",
    "CODE_SIGN_IDENTITY=-"
  ]
}
```

Expected: build succeeds.

- [ ] **Step 4: Run final app tests**

Tool: `xcodebuildmcp-test_sim` with input:

```json
{
  "extraArgs": [
    "-configuration",
    "Debug",
    "CODE_SIGN_IDENTITY=-"
  ],
  "progress": true
}
```

Expected: tests pass or match baseline failures from Task 1.

- [ ] **Step 5: Run final widget build**

Tool: `xcodebuildmcp-session_set_defaults` with input:

```json
{
  "projectPath": "/Users/tigerguo/git/copilot-worktrees/HHappyDocs/huahuahu-vigilant-giggle/HDiary.xcodeproj",
  "scheme": "HDiaryWidgetExtension",
  "simulatorId": "A044BA15-7770-48E6-8E28-E2123A772ACD",
  "simulatorName": "hdiary 17pro"
}
```

Then call `xcodebuildmcp-build_sim` with input:

```json
{
  "extraArgs": [
    "-configuration",
    "Debug",
    "CODE_SIGN_IDENTITY=-"
  ]
}
```

Expected: widget build succeeds.

- [ ] **Step 6: Verify no forbidden resource migration happened**

Run:

```bash
git --no-pager diff --name-status main...HEAD -- \
  'HDiary/Info.plist' \
  'HDiary/HDiary.entitlements' \
  'HDiary/Configs' \
  'HDiary/IAP/HDiary.storekit' \
  'HDiary/Assets.xcassets' \
  'HDiary/Localizable.xcstrings' \
  'HDiaryWidget/Info.plist' \
  'HDiaryWidget/Assets.xcassets' \
  'HDiaryWidget/Localizable.xcstrings'
```

Expected: no output, except `HDiary/HDiary.xctestplan` is intentionally changed outside this command.

- [ ] **Step 7: Audit rename-heavy diff**

Run:

```bash
git --no-pager diff --summary main...HEAD
git --no-pager diff --name-status -M main...HEAD | sed -n '1,220p'
```

Expected: app/widget/unit/UI Swift files primarily show as `R` renames; intentional non-rename modifications are limited to:

```text
HDiary/HDiaryApp.swift
HDiaryWidget/HDiaryWidgetBundle.swift
HDiaryLibrary/Sources/HDiaryAppFeature/HDiaryApp.swift
HDiaryLibrary/Sources/HDiaryWidgetFeature/HDiaryWidgetBundle.swift
HDiaryLibrary/Tests/HDiaryAppFeatureTests/AllTagsViewTests.swift
HDiaryLibrary/Package.swift
HDiary.xcodeproj/project.pbxproj
HDiary/HDiary.xctestplan
docs/superpowers/specs/2026-07-05-swift-package-migration-design.md
docs/superpowers/plans/2026-07-05-swift-package-product-migration.md
```

- [ ] **Step 8: Commit final plan file if still uncommitted**

Run:

```bash
if git diff --quiet -- docs/superpowers/plans/2026-07-05-swift-package-product-migration.md && \
   git diff --cached --quiet -- docs/superpowers/plans/2026-07-05-swift-package-product-migration.md; then
  echo "Plan file already committed or unchanged"
else
  git add docs/superpowers/plans/2026-07-05-swift-package-product-migration.md
  git commit -m "docs: add swift package migration plan" -m "Co-authored-by: Copilot App <223556219+Copilot@users.noreply.github.com>"
fi
```

Expected: if the plan was uncommitted, a docs commit is created; if it was already committed, Git reports nothing to commit.

---

## Self-Review Notes

- Spec coverage: app source migration is Task 2; widget source migration is Task 3; unit test package migration is Task 4; UI test physical move with Xcode ownership is Task 5; resource non-migration and final verification are Task 6.
- Placeholder scan: no red-flag placeholder terms or unspecified implementation steps remain; every code change step includes exact patch content or exact file content.
- Type consistency: package entry names are `HDiaryFeatureApp` and `HDiaryWidgetFeatureBundle`; Xcode shims import `HDiaryAppFeature` and `HDiaryWidgetFeature`; unit tests import `HDiaryAppFeature`.
