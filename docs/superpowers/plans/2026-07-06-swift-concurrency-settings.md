# Swift Concurrency Settings Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将当前分支升级到 SwiftPM 6.3 / Xcode Swift 6，并按模块性质开启完整 strict concurrency 与 Default Main Actor。

**Architecture:** 先改配置，不改业务结构：SwiftPM target 通过 manifest 内的共享 `SwiftSetting` 数组声明语言模式、strict concurrency 和按需 MainActor；Xcode target 通过 xcconfig 声明 Swift 6 与 App/Widget 的默认 MainActor。构建暴露的 Swift 6 并发错误只在编译器点名的源文件中修复，避免无关重构。

**Tech Stack:** Swift 6.3 PackageDescription、SwiftPM、Xcode xcconfig、XcodeBuildMCP、iOS Simulator。

## Global Constraints

- `HSharedCode/Package.swift` 与 `HDiaryLibrary/Package.swift` 必须使用 `// swift-tools-version: 6.3`。
- Xcode targets 必须使用 `SWIFT_VERSION = 6.0`。
- SwiftPM targets 必须使用 `.swiftLanguageMode(.v6)` 和 `.enableUpcomingFeature("StrictConcurrency")`。
- Xcode targets 必须显式设置 `SWIFT_STRICT_CONCURRENCY = complete`。
- 只给 UI/App lifecycle/Widget/UIKit/SwiftUI 组件模块开启 Default Main Actor：`HUIComponent`、`HLocation`、`HDiaryAppFeature`、`HDiaryWidgetFeature`、App target、Widget Extension target。
- 非 UI 模块保持默认 `nonisolated`：`HLocalization`、`HFoundation`、`HMedia`、`HDiaryModel`、`HDiarySearch`、`HDiaryConstants`、`HDiaryIAP`。
- 所有 test targets 默认不启用 Default Main Actor，除非编译器明确指出测试代码必须跟随 UI isolation。
- 不升级第三方依赖版本，除非 SwiftPM resolution 因 Swift 6.3 明确要求。
- 不使用 `@unchecked Sendable` 作为迁移捷径；只有类型已有可验证内部同步且没有更安全方案时才允许。
- 任何会联网的 `swift package resolve`、`swift build` 或 Xcode SwiftPM 解析命令都必须带本地代理环境；如果出现 `fatal: cannot use bare repository ... safe.bareRepository is 'explicit'`，只对该命令加一次性 `GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=safe.bareRepository GIT_CONFIG_VALUE_0=all`，不要改全局 Git 配置。

---

## File Structure

- Modify: `HSharedCode/Package.swift`
  - 升级 manifest tools version。
  - 添加 `packageSwiftSettings` 和 `mainActorPackageSwiftSettings`。
  - 给所有 targets 加 Swift 6/strict concurrency；只给 `HUIComponent`、`HLocation` 加 Default Main Actor。
- Modify: `HDiaryLibrary/Package.swift`
  - 升级 manifest tools version。
  - 添加 `packageSwiftSettings` 和 `mainActorPackageSwiftSettings`。
  - 给所有 targets 加 Swift 6/strict concurrency；只给 `HDiaryAppFeature`、`HDiaryWidgetFeature` 加 Default Main Actor。
- Modify: `HDiary/Configs/base.xcconfig`
  - 将 `SWIFT_VERSION` 从 `5.0` 改为 `6.0`。
  - 添加 `SWIFT_STRICT_CONCURRENCY = complete`。
- Modify: `HDiary/Configs/app.xcconfig`
  - 添加 `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`。
- Modify: `HDiary/Configs/widget.xcconfig`
  - 添加 `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`。
- Potential Modify: compiler-diagnostic files under `HSharedCode/Sources`, `HSharedCode/Tests`, `HDiaryLibrary/Sources`, `HDiaryLibrary/Tests`, `HDiary`, `HDiaryWidget`, or UI test folders.
  - 只修改 Swift 6 strict concurrency 编译器明确报错的文件。
  - 修改类型由诊断决定：`@MainActor` 边界、`Sendable`、`await`、共享状态隔离、或测试隔离。

---

### Task 1: Configure `HSharedCode` SwiftPM targets

**Files:**
- Modify: `HSharedCode/Package.swift:1-93`

**Interfaces:**
- Consumes: `PackageDescription.SwiftSetting.swiftLanguageMode(_:)`、`SwiftSetting.enableUpcomingFeature(_:)`、`SwiftSetting.defaultIsolation(_:)`。
- Produces:
  - `let packageSwiftSettings: [SwiftSetting]`
  - `let mainActorPackageSwiftSettings: [SwiftSetting]`
  - `HSharedCode` targets compiled in Swift 6 language mode with strict concurrency.
  - `HUIComponent` and `HLocation` compiled with default MainActor isolation.

- [ ] **Step 1: Write the failing configuration check**

Run:

```bash
test "$(sed -n '1p' HSharedCode/Package.swift)" = "// swift-tools-version: 6.3" &&
rg -q "let packageSwiftSettings: \\[SwiftSetting\\]" HSharedCode/Package.swift &&
rg -q "\\.swiftLanguageMode\\(\\.v6\\)" HSharedCode/Package.swift &&
rg -q "\\.enableUpcomingFeature\\(\"StrictConcurrency\"\\)" HSharedCode/Package.swift &&
rg -q "\\.defaultIsolation\\(MainActor\\.self\\)" HSharedCode/Package.swift
```

Expected: FAIL because the manifest currently uses Swift tools 5.9 and has no shared Swift settings.

- [ ] **Step 2: Update the tools version and add shared settings**

Edit `HSharedCode/Package.swift` so the top of the file becomes:

```swift
// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let packageSwiftSettings: [SwiftSetting] = [
  .swiftLanguageMode(.v6),
  .enableUpcomingFeature("StrictConcurrency"),
]

let mainActorPackageSwiftSettings: [SwiftSetting] = packageSwiftSettings + [
  .defaultIsolation(MainActor.self),
]

let package = Package(
```

- [ ] **Step 3: Apply settings to `HSharedCode` targets**

In the `targets:` array of `HSharedCode/Package.swift`, add `swiftSettings` exactly as follows:

```swift
.target(
  name: "HLocalization",
  dependencies: [],
  resources: [
    .process("Resources/Localizable.xcstrings"),
  ],
  swiftSettings: packageSwiftSettings
),
.testTarget(
  name: "HLocalizationTests",
  dependencies: ["HLocalization"],
  swiftSettings: packageSwiftSettings
),
.target(
  name: "HFoundation",
  dependencies: ["SwiftSoup"],
  swiftSettings: packageSwiftSettings
),
.testTarget(
  name: "HFoundationTests",
  dependencies: ["HFoundation"],
  swiftSettings: packageSwiftSettings
),
.target(
  name: "HMedia",
  dependencies: ["HFoundation"],
  swiftSettings: packageSwiftSettings
),
.testTarget(
  name: "HMediaTests",
  dependencies: ["HMedia"],
  swiftSettings: packageSwiftSettings
),
.target(
  name: "HUIComponent",
  dependencies: [
    "HLocalization",
    "HFoundation",
    "HMedia",
  ],
  resources: [
    .process("Resources/Localizable.xcstrings"),
  ],
  swiftSettings: mainActorPackageSwiftSettings
),
.testTarget(
  name: "HUIComponentTests",
  dependencies: ["HUIComponent"],
  swiftSettings: packageSwiftSettings
),
.target(
  name: "HLocation",
  dependencies: [],
  swiftSettings: mainActorPackageSwiftSettings
),
.testTarget(
  name: "HLocationTests",
  dependencies: ["HLocation"],
  swiftSettings: packageSwiftSettings
),
```

- [ ] **Step 4: Run the configuration check**

Run:

```bash
test "$(sed -n '1p' HSharedCode/Package.swift)" = "// swift-tools-version: 6.3" &&
rg -q "let packageSwiftSettings: \\[SwiftSetting\\]" HSharedCode/Package.swift &&
rg -q "\\.swiftLanguageMode\\(\\.v6\\)" HSharedCode/Package.swift &&
rg -q "\\.enableUpcomingFeature\\(\"StrictConcurrency\"\\)" HSharedCode/Package.swift &&
rg -q "\\.defaultIsolation\\(MainActor\\.self\\)" HSharedCode/Package.swift
```

Expected: PASS.

- [ ] **Step 5: Validate the manifest syntax**

Run:

```bash
swift package --package-path HSharedCode dump-package >/tmp/hsharedcode-package.json
```

Expected: command exits 0 and `/tmp/hsharedcode-package.json` is created.

- [ ] **Step 6: Commit**

Run:

```bash
git add HSharedCode/Package.swift
git commit -m $'chore: update HSharedCode Swift settings\n\nCo-authored-by: Copilot App <223556219+Copilot@users.noreply.github.com>'
```

---

### Task 2: Configure `HDiaryLibrary` SwiftPM targets

**Files:**
- Modify: `HDiaryLibrary/Package.swift:1-143`

**Interfaces:**
- Consumes:
  - `packageSwiftSettings` shape from Task 1.
  - `mainActorPackageSwiftSettings` shape from Task 1.
- Produces:
  - `HDiaryLibrary` targets compiled in Swift 6 language mode with strict concurrency.
  - `HDiaryAppFeature` and `HDiaryWidgetFeature` compiled with default MainActor isolation.

- [ ] **Step 1: Write the failing configuration check**

Run:

```bash
test "$(sed -n '1p' HDiaryLibrary/Package.swift)" = "// swift-tools-version: 6.3" &&
rg -q "let packageSwiftSettings: \\[SwiftSetting\\]" HDiaryLibrary/Package.swift &&
rg -q "\\.swiftLanguageMode\\(\\.v6\\)" HDiaryLibrary/Package.swift &&
rg -q "\\.enableUpcomingFeature\\(\"StrictConcurrency\"\\)" HDiaryLibrary/Package.swift &&
rg -q "\\.defaultIsolation\\(MainActor\\.self\\)" HDiaryLibrary/Package.swift
```

Expected: FAIL because the manifest currently uses Swift tools 5.9 and has no shared Swift settings.

- [ ] **Step 2: Update the tools version and add shared settings**

Edit `HDiaryLibrary/Package.swift` so the top of the file becomes:

```swift
// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let packageSwiftSettings: [SwiftSetting] = [
  .swiftLanguageMode(.v6),
  .enableUpcomingFeature("StrictConcurrency"),
]

let mainActorPackageSwiftSettings: [SwiftSetting] = packageSwiftSettings + [
  .defaultIsolation(MainActor.self),
]

let package = Package(
```

- [ ] **Step 3: Apply settings to `HDiaryLibrary` targets**

In the `targets:` array of `HDiaryLibrary/Package.swift`, add `swiftSettings` exactly as follows:

```swift
.target(
  name: "HDiaryModel",
  dependencies: [
    "HDiaryConstants",
    .product(name: "HFoundation", package: "HSharedCode"),
    .product(name: "HMedia", package: "HSharedCode"),
    .product(name: "Algorithms", package: "swift-algorithms"),
  ],
  resources: [
    .process("Resources"),
  ],
  swiftSettings: packageSwiftSettings
),
.target(
  name: "HDiarySearch",
  dependencies: [
    "HDiaryConstants",
    "HDiaryModel",
    .product(name: "Atomics", package: "swift-atomics"),
  ],
  swiftSettings: packageSwiftSettings
),
.testTarget(
  name: "HDiarySearchTests",
  dependencies: [
    "HDiarySearch",
    "HDiaryModel",
    .product(name: "Atomics", package: "swift-atomics"),
  ],
  swiftSettings: packageSwiftSettings
),
.testTarget(
  name: "HDiaryModelTests",
  dependencies: [
    "HDiaryModel",
    .product(name: "HFoundation", package: "HSharedCode"),
  ],
  swiftSettings: packageSwiftSettings
),
.target(
  name: "HDiaryConstants",
  dependencies: [
    .product(name: "HUIComponent", package: "HSharedCode"),
  ],
  swiftSettings: packageSwiftSettings
),
.testTarget(
  name: "HDiaryConstantsTests",
  dependencies: [
    "HDiaryConstants",
  ],
  swiftSettings: packageSwiftSettings
),
.target(
  name: "HDiaryIAP",
  dependencies: [
    "HDiaryConstants",
  ],
  resources: [
    .process("Resources"),
  ],
  swiftSettings: packageSwiftSettings
),
.testTarget(
  name: "HDiaryIAPTests",
  dependencies: [
    "HDiaryIAP",
  ],
  swiftSettings: packageSwiftSettings
),
.target(
  name: "HDiaryAppFeature",
  dependencies: [
    "HDiaryConstants",
    "HDiaryIAP",
    "HDiaryModel",
    "HDiarySearch",
    .product(name: "HFoundation", package: "HSharedCode"),
    .product(name: "HLocalization", package: "HSharedCode"),
    .product(name: "HMedia", package: "HSharedCode"),
    .product(name: "HUIComponent", package: "HSharedCode"),
    .product(name: "SFSafeSymbols", package: "SFSafeSymbols"),
  ],
  swiftSettings: mainActorPackageSwiftSettings
),
.target(
  name: "HDiaryWidgetFeature",
  dependencies: [
    "HDiaryConstants",
    "HDiaryModel",
  ],
  swiftSettings: mainActorPackageSwiftSettings
),
.testTarget(
  name: "HDiaryAppFeatureTests",
  dependencies: [
    "HDiaryAppFeature",
  ],
  swiftSettings: packageSwiftSettings
),
```

- [ ] **Step 4: Run the configuration check**

Run:

```bash
test "$(sed -n '1p' HDiaryLibrary/Package.swift)" = "// swift-tools-version: 6.3" &&
rg -q "let packageSwiftSettings: \\[SwiftSetting\\]" HDiaryLibrary/Package.swift &&
rg -q "\\.swiftLanguageMode\\(\\.v6\\)" HDiaryLibrary/Package.swift &&
rg -q "\\.enableUpcomingFeature\\(\"StrictConcurrency\"\\)" HDiaryLibrary/Package.swift &&
rg -q "\\.defaultIsolation\\(MainActor\\.self\\)" HDiaryLibrary/Package.swift
```

Expected: PASS.

- [ ] **Step 5: Validate the manifest syntax**

Run:

```bash
swift package --package-path HDiaryLibrary dump-package >/tmp/hdiarylibrary-package.json
```

Expected: command exits 0 and `/tmp/hdiarylibrary-package.json` is created.

- [ ] **Step 6: Commit**

Run:

```bash
git add HDiaryLibrary/Package.swift
git commit -m $'chore: update HDiaryLibrary Swift settings\n\nCo-authored-by: Copilot App <223556219+Copilot@users.noreply.github.com>'
```

---

### Task 3: Configure Xcode Swift settings in xcconfig files

**Files:**
- Modify: `HDiary/Configs/base.xcconfig:11-18`
- Modify: `HDiary/Configs/app.xcconfig:1-27`
- Modify: `HDiary/Configs/widget.xcconfig:1-13`

**Interfaces:**
- Consumes: Xcode build settings `SWIFT_VERSION`、`SWIFT_STRICT_CONCURRENCY`、`SWIFT_DEFAULT_ACTOR_ISOLATION`。
- Produces:
  - All Xcode targets inherit Swift 6 language mode and complete strict concurrency from `base.xcconfig`.
  - App and Widget targets inherit MainActor default isolation from their target-specific xcconfigs.
  - Unit/UI test xcconfigs remain nonisolated because they only include `base.xcconfig`.

- [ ] **Step 1: Write the failing configuration check**

Run:

```bash
rg -q "^SWIFT_VERSION = 6\\.0$" HDiary/Configs/base.xcconfig &&
rg -q "^SWIFT_STRICT_CONCURRENCY = complete$" HDiary/Configs/base.xcconfig &&
rg -q "^SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor$" HDiary/Configs/app.xcconfig &&
rg -q "^SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor$" HDiary/Configs/widget.xcconfig &&
! rg -q "^SWIFT_DEFAULT_ACTOR_ISOLATION" HDiary/Configs/unit-tests.xcconfig HDiary/Configs/ui-tests.xcconfig
```

Expected: FAIL because `SWIFT_VERSION` is currently `5.0` and no concurrency settings exist.

- [ ] **Step 2: Update shared Xcode Swift settings**

Edit `HDiary/Configs/base.xcconfig` lines 11-18 to this block:

```xcconfig
MARKETING_VERSION = 1.14
CURRENT_PROJECT_VERSION = 1
DEVELOPMENT_TEAM = F29WG8477A
CODE_SIGN_STYLE = Automatic
GENERATE_INFOPLIST_FILE = YES
IPHONEOS_DEPLOYMENT_TARGET = 17.0
SWIFT_VERSION = 6.0
SWIFT_STRICT_CONCURRENCY = complete
TARGETED_DEVICE_FAMILY = 1,2
```

- [ ] **Step 3: Add Default Main Actor for the App target**

Append this line to `HDiary/Configs/app.xcconfig` after `SWIFT_EMIT_LOC_STRINGS = YES`:

```xcconfig
SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor
```

- [ ] **Step 4: Add Default Main Actor for the Widget target**

Append this line to `HDiary/Configs/widget.xcconfig` after `SWIFT_EMIT_LOC_STRINGS = YES`:

```xcconfig
SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor
```

- [ ] **Step 5: Run the configuration check**

Run:

```bash
rg -q "^SWIFT_VERSION = 6\\.0$" HDiary/Configs/base.xcconfig &&
rg -q "^SWIFT_STRICT_CONCURRENCY = complete$" HDiary/Configs/base.xcconfig &&
rg -q "^SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor$" HDiary/Configs/app.xcconfig &&
rg -q "^SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor$" HDiary/Configs/widget.xcconfig &&
! rg -q "^SWIFT_DEFAULT_ACTOR_ISOLATION" HDiary/Configs/unit-tests.xcconfig HDiary/Configs/ui-tests.xcconfig
```

Expected: PASS.

- [ ] **Step 6: Reset XcodeBuildMCP defaults to this worktree**

Use XcodeBuildMCP:

```text
session_show_defaults
```

If `projectPath` is not `/Users/tigerguo/git/copilot-worktrees/HHappyDocs/huahuahu-psychic-umbrella/HDiary.xcodeproj`, call:

```text
session_set_defaults(
  projectPath: "/Users/tigerguo/git/copilot-worktrees/HHappyDocs/huahuahu-psychic-umbrella/HDiary.xcodeproj",
  scheme: "HDiary",
  simulatorId: "A044BA15-7770-48E6-8E28-E2123A772ACD",
  simulatorName: "hdiary 17pro",
  simulatorPlatform: "iOS Simulator"
)
```

Expected: active defaults point at the current worktree, not `/Users/tigerguo/git/HHappyDocs`.

- [ ] **Step 7: Inspect build settings**

Use XcodeBuildMCP:

```text
show_build_settings
```

Expected:

```text
SWIFT_VERSION = 6.0
SWIFT_STRICT_CONCURRENCY = complete
SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor
```

`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` should appear for App/Widget build settings and should not be introduced through `unit-tests.xcconfig` or `ui-tests.xcconfig`.

- [ ] **Step 8: Commit**

Run:

```bash
git add HDiary/Configs/base.xcconfig HDiary/Configs/app.xcconfig HDiary/Configs/widget.xcconfig
git commit -m $'chore: enable Swift 6 Xcode settings\n\nCo-authored-by: Copilot App <223556219+Copilot@users.noreply.github.com>'
```

---

### Task 4: Build, fix strict-concurrency diagnostics, and verify

**Files:**
- Modify: only Swift files named by compiler diagnostics under:
  - `HSharedCode/Sources/**`
  - `HSharedCode/Tests/**`
  - `HDiaryLibrary/Sources/**`
  - `HDiaryLibrary/Tests/**`
  - `HDiary/**`
  - `HDiaryWidget/**`
  - `HDiaryLibrary/UITests/**`

**Interfaces:**
- Consumes:
  - SwiftPM settings from Tasks 1-2.
  - Xcode xcconfig settings from Task 3.
- Produces:
  - `HSharedCode` builds with Swift 6 strict concurrency.
  - `HDiaryLibrary` builds with Swift 6 strict concurrency.
  - Xcode scheme `HDiary` builds for the configured simulator.

- [ ] **Step 1: Build `HSharedCode` with tests enabled**

Run:

```bash
GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=safe.bareRepository GIT_CONFIG_VALUE_0=all HTTP_PROXY=http://127.0.0.1:1082 HTTPS_PROXY=http://127.0.0.1:1082 ALL_PROXY=http://127.0.0.1:1082 http_proxy=http://127.0.0.1:1082 https_proxy=http://127.0.0.1:1082 all_proxy=http://127.0.0.1:1082 NO_PROXY=localhost,127.0.0.1,::1 no_proxy=localhost,127.0.0.1,::1 swift build --package-path HSharedCode --build-tests 2>&1 | tee /tmp/hsharedcode-swift6-build.log
```

Expected if clean: exit 0.

Expected if migration work remains: compiler diagnostics are written to `/tmp/hsharedcode-swift6-build.log`. Continue with Steps 2-4 for each diagnostic, then rerun Step 1.

- [ ] **Step 2: Fix `HSharedCode` diagnostics by category**

For each diagnostic in `/tmp/hsharedcode-swift6-build.log`, apply exactly one of these fixes:

```text
Diagnostic contains: "static property" and "is not concurrency-safe"
Preferred fix:
  - If the value is immutable and its stored properties are Sendable, make the type conform to Sendable.
  - If the declaration calls UIKit/SwiftUI/main-thread APIs, add @MainActor to the declaration or enclosing type.
  - If it is mutable shared state, replace it with actor isolation or remove the shared mutable state.
Do not use nonisolated(unsafe) unless the value is truly immutable and compiler visibility is the only issue.
```

```text
Diagnostic contains: "capture of" and "with non-sendable type in a @Sendable closure"
Preferred fix:
  - Capture immutable scalar/value data before the closure: let id = object.id.
  - Make value types conform to Sendable only when all stored properties are Sendable.
  - Keep UI work on MainActor instead of sending UI objects across isolation.
Do not add @unchecked Sendable.
```

```text
Diagnostic contains: "main actor-isolated" or "call to main actor-isolated"
Preferred fix:
  - If caller is UI/lifecycle code, annotate the caller or enclosing type with @MainActor.
  - If caller is async and legitimately crosses actors, add await.
  - If caller is non-async and cannot become async, move the boundary outward; avoid adding Task {} unless this is lifecycle fire-and-forget work with explicit cancellation irrelevance.
```

```text
Diagnostic contains: "sending" and "risks causing data races"
Preferred fix:
  - Avoid crossing the isolation boundary by moving the call onto the same actor.
  - If ownership is truly transferred and Swift accepts it, use sending parameter only at the boundary.
  - Prefer value types or actors over shared mutable classes.
```

- [ ] **Step 3: Rebuild `HSharedCode` after each fix batch**

Run:

```bash
GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=safe.bareRepository GIT_CONFIG_VALUE_0=all HTTP_PROXY=http://127.0.0.1:1082 HTTPS_PROXY=http://127.0.0.1:1082 ALL_PROXY=http://127.0.0.1:1082 http_proxy=http://127.0.0.1:1082 https_proxy=http://127.0.0.1:1082 all_proxy=http://127.0.0.1:1082 NO_PROXY=localhost,127.0.0.1,::1 no_proxy=localhost,127.0.0.1,::1 swift build --package-path HSharedCode --build-tests
```

Expected: PASS before moving to `HDiaryLibrary`.

- [ ] **Step 4: Commit `HSharedCode` diagnostic fixes if any source files changed**

Run only if `git status --short HSharedCode` shows files outside `HSharedCode/Package.swift`:

```bash
git add HSharedCode/Sources HSharedCode/Tests
git commit -m $'fix: resolve HSharedCode Swift concurrency diagnostics\n\nCo-authored-by: Copilot App <223556219+Copilot@users.noreply.github.com>'
```

- [ ] **Step 5: Build `HDiaryLibrary` with tests enabled**

Run:

```bash
GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=safe.bareRepository GIT_CONFIG_VALUE_0=all HTTP_PROXY=http://127.0.0.1:1082 HTTPS_PROXY=http://127.0.0.1:1082 ALL_PROXY=http://127.0.0.1:1082 http_proxy=http://127.0.0.1:1082 https_proxy=http://127.0.0.1:1082 all_proxy=http://127.0.0.1:1082 NO_PROXY=localhost,127.0.0.1,::1 no_proxy=localhost,127.0.0.1,::1 swift build --package-path HDiaryLibrary --build-tests 2>&1 | tee /tmp/hdiarylibrary-swift6-build.log
```

Expected if clean: exit 0.

Expected if migration work remains: compiler diagnostics are written to `/tmp/hdiarylibrary-swift6-build.log`. Use the same fix categories from Step 2, then rerun Step 5.

- [ ] **Step 6: Rebuild `HDiaryLibrary` after fixes**

Run:

```bash
GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=safe.bareRepository GIT_CONFIG_VALUE_0=all HTTP_PROXY=http://127.0.0.1:1082 HTTPS_PROXY=http://127.0.0.1:1082 ALL_PROXY=http://127.0.0.1:1082 http_proxy=http://127.0.0.1:1082 https_proxy=http://127.0.0.1:1082 all_proxy=http://127.0.0.1:1082 NO_PROXY=localhost,127.0.0.1,::1 no_proxy=localhost,127.0.0.1,::1 swift build --package-path HDiaryLibrary --build-tests
```

Expected: PASS before moving to Xcode build.

- [ ] **Step 7: Commit `HDiaryLibrary` diagnostic fixes if any source files changed**

Run only if `git status --short HDiaryLibrary` shows files outside `HDiaryLibrary/Package.swift`:

```bash
git add HDiaryLibrary/Sources HDiaryLibrary/Tests
git commit -m $'fix: resolve HDiaryLibrary Swift concurrency diagnostics\n\nCo-authored-by: Copilot App <223556219+Copilot@users.noreply.github.com>'
```

- [ ] **Step 8: Build the Xcode simulator scheme**

Use XcodeBuildMCP:

```text
session_show_defaults
```

If defaults are wrong, call the same `session_set_defaults` from Task 3 Step 6. Then use XcodeBuildMCP:

```text
build_sim
```

Expected if clean: build succeeds for scheme `HDiary` on simulator `hdiary 17pro`.

Expected if migration work remains: Xcode compiler diagnostics identify exact Swift files. Use the same fix categories from Step 2 and rerun `build_sim`.

- [ ] **Step 9: Commit Xcode-only diagnostic fixes if any source files changed**

Run only if `git status --short HDiary HDiaryWidget HDiaryLibrary/UITests` shows changed Swift files:

```bash
git add HDiary HDiaryWidget HDiaryLibrary/UITests
git commit -m $'fix: resolve app Swift concurrency diagnostics\n\nCo-authored-by: Copilot App <223556219+Copilot@users.noreply.github.com>'
```

- [ ] **Step 10: Run available tests**

Run SwiftPM tests:

```bash
GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=safe.bareRepository GIT_CONFIG_VALUE_0=all HTTP_PROXY=http://127.0.0.1:1082 HTTPS_PROXY=http://127.0.0.1:1082 ALL_PROXY=http://127.0.0.1:1082 http_proxy=http://127.0.0.1:1082 https_proxy=http://127.0.0.1:1082 all_proxy=http://127.0.0.1:1082 NO_PROXY=localhost,127.0.0.1,::1 no_proxy=localhost,127.0.0.1,::1 swift test --package-path HSharedCode
GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=safe.bareRepository GIT_CONFIG_VALUE_0=all HTTP_PROXY=http://127.0.0.1:1082 HTTPS_PROXY=http://127.0.0.1:1082 ALL_PROXY=http://127.0.0.1:1082 http_proxy=http://127.0.0.1:1082 https_proxy=http://127.0.0.1:1082 all_proxy=http://127.0.0.1:1082 NO_PROXY=localhost,127.0.0.1,::1 no_proxy=localhost,127.0.0.1,::1 swift test --package-path HDiaryLibrary
```

Use XcodeBuildMCP:

```text
test_sim
```

Expected: existing tests pass. If a test fails because Swift 6 isolation changed a test boundary, make the test isolation explicit with `@MainActor` only on the failing test type/function, then rerun the same test command.

- [ ] **Step 11: Final status check**

Run:

```bash
git --no-pager status --short --branch
git --no-pager log --oneline -6
```

Expected: branch contains commits for package settings, Xcode settings, and any necessary diagnostic fixes. Working tree should be clean except for intentional uncommitted plan/spec files if the executor chose not to commit planning documents.
