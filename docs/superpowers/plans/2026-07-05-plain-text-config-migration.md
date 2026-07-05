# 纯文本配置与 Swift Package 迁移 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 第一波迁移将 Xcode build settings 外置到 xcconfig，并把 app target 中两个非 UI 逻辑区域迁入 Swift Package。

**Architecture:** 保留 `HDiary.xcodeproj` 作为 app/widget/test target 壳层；把 project-level 和 target-level build settings 分层放入 `HDiary/Configs/*.xcconfig`。代码迁移先处理低风险逻辑：启动数据维护进入 `HDiaryModel`，搜索 model/view-model 进入新增 `HDiarySearch` package target，SwiftUI view 留在 app target 作为集成层。

**Tech Stack:** Xcode project、xcconfig、SwiftPM、SwiftData、SwiftUI Observation、XCTest、XcodeBuildMCP。

## Global Constraints

- 保留现有 `HDiary.xcodeproj`；不引入 XcodeGen、Tuist 或其他项目生成工具。
- 不把 `.xcodeproj` 完全变成生成物；target membership、build phases、embedded extension、Package product dependency、scheme 仍由 Xcode project 表达。
- 不修改 SwiftData schema、CloudKit database、relationship、model property 或持久化路径。
- 每个任务结束时必须保持 `HDiary` app target 可构建。
- Package 不能反向依赖 app target；依赖方向保持 `HDiary app / HDiaryWidget -> feature/domain package targets -> HDiaryLibrary targets -> HSharedCode targets`。
- Swift Package 网络解析命令必须带本地代理环境；如果遇到 SwiftPM bare repository 安全错误，用单次 `GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=safe.bareRepository GIT_CONFIG_VALUE_0=all` 前缀，不修改全局 Git config。
- 任何 XcodeBuildMCP build/test/run 调用前，先调用 `xcodebuildmcp-session_show_defaults`；defaults 缺失或不匹配时，按 `.xcodebuildmcp/config.yaml` 设置绝对 `projectPath`。
- commit message 必须包含 trailer：`Co-authored-by: Copilot App <223556219+Copilot@users.noreply.github.com>`。

---

## Scope Check

本计划实现设计文档的第一波可验证迁移：

1. 完成 project-level 和 target-level build settings 的 xcconfig 外置。
2. 将启动数据维护逻辑从 `BaseTabView` 移到 `HDiaryModel`。
3. 新增 `HDiarySearch` package target，并将搜索 model/view-model 从 app target 移入 package。

不包含 feature view 大规模迁移；设计文档将 feature view 迁移定义为基础 service 和组件稳定后的单独评估项。

---

## File Structure

- Modify: `HDiary/Configs/base.xcconfig` — 共享版本号、签名、deployment target、Swift version 等基础 build settings。
- Modify: `HDiary/Configs/debug.xcconfig` — project-level Debug build settings。
- Modify: `HDiary/Configs/release.xcconfig` — project-level Release build settings。
- Create: `HDiary/Configs/app.xcconfig` — app target 共享 build settings。
- Create: `HDiary/Configs/app-debug.xcconfig` — app Debug bundle id 入口配置。
- Create: `HDiary/Configs/app-release.xcconfig` — app Release bundle id 入口配置。
- Create: `HDiary/Configs/widget.xcconfig` — widget target 共享 build settings。
- Create: `HDiary/Configs/widget-debug.xcconfig` — widget Debug bundle id 入口配置。
- Create: `HDiary/Configs/widget-release.xcconfig` — widget Release bundle id 入口配置。
- Create: `HDiary/Configs/unit-tests.xcconfig` — unit test target 共享 build settings。
- Create: `HDiary/Configs/unit-tests-debug.xcconfig` — unit test Debug 入口配置。
- Create: `HDiary/Configs/unit-tests-release.xcconfig` — unit test Release 入口配置。
- Create: `HDiary/Configs/ui-tests.xcconfig` — UI test target 共享 build settings。
- Create: `HDiary/Configs/ui-tests-debug.xcconfig` — UI test Debug 入口配置。
- Create: `HDiary/Configs/ui-tests-release.xcconfig` — UI test Release 入口配置。
- Modify: `HDiary.xcodeproj/project.pbxproj` — 为 target build configurations 添加 `baseConfigurationReferenceRelativePath`，清空已迁移 build settings，更新 xcconfig membership exceptions，新增 `HDiarySearch` product dependency，移除 app 对 `Atomics` 的直接依赖。
- Create: `HDiaryLibrary/Sources/HDiaryModel/ModelOperation/StartupDataMaintenanceService.swift` — 启动时 legacy image migration、media storage size 更新、orphan media 清理、deleted moment 清理。
- Create: `HDiaryLibrary/Tests/HDiaryModelTests/StartupDataMaintenanceServiceTests.swift` — in-memory SwiftData 测试启动维护 service。
- Modify: `HDiary/BaseTabView.swift` — 移除内联数据维护方法，启动时调用 package service。
- Modify: `HDiaryLibrary/Package.swift` — 新增 `HDiarySearch` product/target/test target，并把 `swift-atomics` dependency 转移到 package。
- Move: `HDiary/Search/Model/SearchEngine.swift` -> `HDiaryLibrary/Sources/HDiarySearch/SearchEngine.swift`
- Move: `HDiary/Search/Model/SearchRecommendEngine.swift` -> `HDiaryLibrary/Sources/HDiarySearch/SearchRecommendEngine.swift`
- Move: `HDiary/Search/Model/SearchViewModel.swift` -> `HDiaryLibrary/Sources/HDiarySearch/SearchViewModel.swift`
- Delete: `HDiary/Search/Model/SearchableItem.swift` — 当前没有引用，迁移搜索 model 后移除空置文件。
- Create: `HDiaryLibrary/Tests/HDiarySearchTests/SearchEngineTests.swift` — 验证搜索 engine 使用 in-memory SwiftData container。
- Modify: `HDiary/BaseTabView.swift` — 添加 `import HDiarySearch`。
- Modify: `HDiary/Common/Navigation/AppEnvironments.swift` — 添加 `import HDiarySearch`。
- Modify: `HDiary/Search/View/SearchModifier.swift` — 添加 `import HDiarySearch`。
- Modify: `HDiary/Search/View/SearchView.swift` — 添加 `import HDiarySearch`。
- Modify: `HDiary/Moments/MomentList/MomentTab.swift` — 添加 `import HDiarySearch`。
- Modify: `HDiary.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` and `HDiaryLibrary/Package.resolved` — SwiftPM resolves the new package dependency during Task 5.

---

### Task 1: Establish Build Baseline

**Files:**
- Read: `.xcodebuildmcp/config.yaml`
- Read: `HDiary.xcodeproj/project.pbxproj`
- No file modifications.

**Interfaces:**
- Consumes: current repository state.
- Produces: known-good baseline for app build, package tests, and build settings before migration.

- [ ] **Step 1: Confirm clean or understood working tree**

Run:

```bash
git --no-pager status --short
```

Expected:

```text
```

If output contains unrelated user changes, leave those files untouched and continue only if they do not overlap files listed in this plan.

- [ ] **Step 2: Show XcodeBuildMCP defaults**

Tool call:

```json
{
  "tool": "xcodebuildmcp-session_show_defaults"
}
```

Expected active defaults:

```text
projectPath: /Users/tigerguo/git/copilot-worktrees/HHappyDocs/huahuahu-stunning-bassoon/HDiary.xcodeproj
scheme: HDiary
simulatorName: hdiary 17pro
simulatorId: A044BA15-7770-48E6-8E28-E2123A772ACD
```

If `projectPath` is relative or missing, set it:

```json
{
  "tool": "xcodebuildmcp-session_set_defaults",
  "input": {
    "projectPath": "/Users/tigerguo/git/copilot-worktrees/HHappyDocs/huahuahu-stunning-bassoon/HDiary.xcodeproj",
    "scheme": "HDiary",
    "simulatorId": "A044BA15-7770-48E6-8E28-E2123A772ACD",
    "simulatorName": "hdiary 17pro"
  }
}
```

- [ ] **Step 3: Capture current build settings**

Tool call:

```json
{
  "tool": "xcodebuildmcp-show_build_settings"
}
```

Expected output contains these current values:

```text
PRODUCT_BUNDLE_IDENTIFIER = com.tiger.suzhou.HDiary-Debug
INFOPLIST_FILE = HDiary/Info.plist
CODE_SIGN_ENTITLEMENTS = HDiary/HDiary.entitlements
IPHONEOS_DEPLOYMENT_TARGET = 17.0
SWIFT_VERSION = 5.0
DEVELOPMENT_TEAM = F29WG8477A
```

- [ ] **Step 4: Verify Swift packages before migration**

Run:

```bash
HTTP_PROXY=http://127.0.0.1:1082 HTTPS_PROXY=http://127.0.0.1:1082 ALL_PROXY=http://127.0.0.1:1082 http_proxy=http://127.0.0.1:1082 https_proxy=http://127.0.0.1:1082 all_proxy=http://127.0.0.1:1082 NO_PROXY=localhost,127.0.0.1,::1 no_proxy=localhost,127.0.0.1,::1 GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=safe.bareRepository GIT_CONFIG_VALUE_0=all swift test --package-path HDiaryLibrary

HTTP_PROXY=http://127.0.0.1:1082 HTTPS_PROXY=http://127.0.0.1:1082 ALL_PROXY=http://127.0.0.1:1082 http_proxy=http://127.0.0.1:1082 https_proxy=http://127.0.0.1:1082 all_proxy=http://127.0.0.1:1082 NO_PROXY=localhost,127.0.0.1,::1 no_proxy=localhost,127.0.0.1,::1 GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=safe.bareRepository GIT_CONFIG_VALUE_0=all swift test --package-path HSharedCode
```

Expected: both commands finish with `Test Suite ... passed`.

- [ ] **Step 5: Verify app build before migration**

Tool call:

```json
{
  "tool": "xcodebuildmcp-build_sim",
  "input": {
    "extraArgs": []
  }
}
```

Expected: build succeeds for scheme `HDiary`.

---

### Task 2: Move Project-Level Build Settings into xcconfig

**Files:**
- Modify: `HDiary/Configs/base.xcconfig`
- Modify: `HDiary/Configs/debug.xcconfig`
- Modify: `HDiary/Configs/release.xcconfig`
- Modify: `HDiary.xcodeproj/project.pbxproj`

**Interfaces:**
- Consumes: current project-level build configuration IDs `60A4E2222A3DDCE3000E68A0` (Debug) and `60A4E2232A3DDCE3000E68A0` (Release).
- Produces: project-level Debug/Release settings resolved from xcconfig, with those two pbxproj `buildSettings` dictionaries empty.

- [ ] **Step 1: Replace `base.xcconfig` content**

Use `apply_patch` so the file becomes exactly:

```xcconfig
//
//  base.xcconfig
//  HDiary
//
//  Created by tigerguo on 2023/10/22.
//

// Configuration settings file format documentation can be found at:
// https://help.apple.com/xcode/#/dev745c5c974

MARKETING_VERSION = 1.14
CURRENT_PROJECT_VERSION = 1
DEVELOPMENT_TEAM = F29WG8477A
CODE_SIGN_STYLE = Automatic
GENERATE_INFOPLIST_FILE = YES
IPHONEOS_DEPLOYMENT_TARGET = 17.0
SWIFT_VERSION = 5.0
TARGETED_DEVICE_FAMILY = 1,2
```

- [ ] **Step 2: Replace `debug.xcconfig` content**

Use `apply_patch` so the file becomes exactly:

```xcconfig
//
//  debug.xcconfig
//  HDiary
//
//  Created by tigerguo on 2024/4/12.
//

// Configuration settings file format documentation can be found at:
// https://help.apple.com/xcode/#/dev745c5c974

#include "./base.xcconfig"

ALWAYS_SEARCH_USER_PATHS = NO
ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES
CLANG_ANALYZER_LOCALIZABILITY_NONLOCALIZED = YES
CLANG_ANALYZER_NONNULL = YES
CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE
CLANG_CXX_LANGUAGE_STANDARD = gnu++20
CLANG_ENABLE_MODULES = YES
CLANG_ENABLE_OBJC_ARC = YES
CLANG_ENABLE_OBJC_WEAK = YES
CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES
CLANG_WARN_BOOL_CONVERSION = YES
CLANG_WARN_COMMA = YES
CLANG_WARN_CONSTANT_CONVERSION = YES
CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES
CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR
CLANG_WARN_DOCUMENTATION_COMMENTS = YES
CLANG_WARN_EMPTY_BODY = YES
CLANG_WARN_ENUM_CONVERSION = YES
CLANG_WARN_INFINITE_RECURSION = YES
CLANG_WARN_INT_CONVERSION = YES
CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES
CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES
CLANG_WARN_OBJC_LITERAL_CONVERSION = YES
CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR
CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES
CLANG_WARN_RANGE_LOOP_ANALYSIS = YES
CLANG_WARN_STRICT_PROTOTYPES = YES
CLANG_WARN_SUSPICIOUS_MOVE = YES
CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE
CLANG_WARN_UNREACHABLE_CODE = YES
CLANG_WARN__DUPLICATE_METHOD_MATCH = YES
COPY_PHASE_STRIP = NO
DEAD_CODE_STRIPPING = YES
DEBUG_INFORMATION_FORMAT = dwarf
ENABLE_STRICT_OBJC_MSGSEND = YES
ENABLE_TESTABILITY = YES
ENABLE_USER_SCRIPT_SANDBOXING = YES
GCC_C_LANGUAGE_STANDARD = gnu17
GCC_DYNAMIC_NO_PIC = NO
GCC_NO_COMMON_BLOCKS = YES
GCC_OPTIMIZATION_LEVEL = 0
GCC_PREPROCESSOR_DEFINITIONS = DEBUG=1 $(inherited)
GCC_WARN_64_TO_32_BIT_CONVERSION = YES
GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR
GCC_WARN_UNDECLARED_SELECTOR = YES
GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE
GCC_WARN_UNUSED_FUNCTION = YES
GCC_WARN_UNUSED_VARIABLE = YES
LOCALIZATION_PREFERS_STRING_CATALOGS = YES
MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE
MTL_FAST_MATH = YES
ONLY_ACTIVE_ARCH = YES
SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG $(inherited)
SWIFT_OPTIMIZATION_LEVEL = -Onone
```

- [ ] **Step 3: Replace `release.xcconfig` content**

Use `apply_patch` so the file becomes exactly:

```xcconfig
//
//  release.xcconfig
//  HDiary
//
//  Created by tigerguo on 2024/4/12.
//

// Configuration settings file format documentation can be found at:
// https://help.apple.com/xcode/#/dev745c5c974

#include "./base.xcconfig"

ALWAYS_SEARCH_USER_PATHS = NO
ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES
CLANG_ANALYZER_LOCALIZABILITY_NONLOCALIZED = YES
CLANG_ANALYZER_NONNULL = YES
CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE
CLANG_CXX_LANGUAGE_STANDARD = gnu++20
CLANG_ENABLE_MODULES = YES
CLANG_ENABLE_OBJC_ARC = YES
CLANG_ENABLE_OBJC_WEAK = YES
CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES
CLANG_WARN_BOOL_CONVERSION = YES
CLANG_WARN_COMMA = YES
CLANG_WARN_CONSTANT_CONVERSION = YES
CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES
CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR
CLANG_WARN_DOCUMENTATION_COMMENTS = YES
CLANG_WARN_EMPTY_BODY = YES
CLANG_WARN_ENUM_CONVERSION = YES
CLANG_WARN_INFINITE_RECURSION = YES
CLANG_WARN_INT_CONVERSION = YES
CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES
CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES
CLANG_WARN_OBJC_LITERAL_CONVERSION = YES
CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR
CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES
CLANG_WARN_RANGE_LOOP_ANALYSIS = YES
CLANG_WARN_STRICT_PROTOTYPES = YES
CLANG_WARN_SUSPICIOUS_MOVE = YES
CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE
CLANG_WARN_UNREACHABLE_CODE = YES
CLANG_WARN__DUPLICATE_METHOD_MATCH = YES
COPY_PHASE_STRIP = NO
DEAD_CODE_STRIPPING = YES
DEBUG_INFORMATION_FORMAT = dwarf-with-dsym
ENABLE_NS_ASSERTIONS = NO
ENABLE_STRICT_OBJC_MSGSEND = YES
ENABLE_USER_SCRIPT_SANDBOXING = YES
GCC_C_LANGUAGE_STANDARD = gnu17
GCC_NO_COMMON_BLOCKS = YES
GCC_WARN_64_TO_32_BIT_CONVERSION = YES
GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR
GCC_WARN_UNDECLARED_SELECTOR = YES
GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE
GCC_WARN_UNUSED_FUNCTION = YES
GCC_WARN_UNUSED_VARIABLE = YES
LOCALIZATION_PREFERS_STRING_CATALOGS = YES
MTL_ENABLE_DEBUG_INFO = NO
MTL_FAST_MATH = YES
SWIFT_COMPILATION_MODE = wholemodule
```

- [ ] **Step 4: Empty project-level buildSettings in `project.pbxproj`**

In `HDiary.xcodeproj/project.pbxproj`, keep these existing base config references:

```pbxproj
baseConfigurationReferenceAnchor = 60F3DCB92CDDF1AF00C05BFB /* HDiary */;
baseConfigurationReferenceRelativePath = Configs/debug.xcconfig;
```

and:

```pbxproj
baseConfigurationReferenceAnchor = 60F3DCB92CDDF1AF00C05BFB /* HDiary */;
baseConfigurationReferenceRelativePath = Configs/release.xcconfig;
```

For project Debug config `60A4E2222A3DDCE3000E68A0`, replace the whole `buildSettings = { ... };` block with:

```pbxproj
buildSettings = {
};
```

For project Release config `60A4E2232A3DDCE3000E68A0`, replace the whole `buildSettings = { ... };` block with:

```pbxproj
buildSettings = {
};
```

- [ ] **Step 5: Verify migrated project settings still resolve**

Tool call:

```json
{
  "tool": "xcodebuildmcp-show_build_settings"
}
```

Expected output still contains:

```text
CLANG_CXX_LANGUAGE_STANDARD = gnu++20
LOCALIZATION_PREFERS_STRING_CATALOGS = YES
SWIFT_OPTIMIZATION_LEVEL = -Onone
SWIFT_VERSION = 5.0
MARKETING_VERSION = 1.14
```

- [ ] **Step 6: Build after project-level config migration**

Tool call:

```json
{
  "tool": "xcodebuildmcp-build_sim",
  "input": {
    "extraArgs": []
  }
}
```

Expected: build succeeds.

- [ ] **Step 7: Commit project-level config migration**

Run:

```bash
git add HDiary/Configs/base.xcconfig HDiary/Configs/debug.xcconfig HDiary/Configs/release.xcconfig HDiary.xcodeproj/project.pbxproj
git commit -m "chore: move project build settings to xcconfig" -m "Co-authored-by: Copilot App <223556219+Copilot@users.noreply.github.com>"
```

Expected: one commit containing only the project-level xcconfig migration.

---

### Task 3: Move Target-Level Build Settings into xcconfig

**Files:**
- Create: `HDiary/Configs/app.xcconfig`
- Create: `HDiary/Configs/app-debug.xcconfig`
- Create: `HDiary/Configs/app-release.xcconfig`
- Create: `HDiary/Configs/widget.xcconfig`
- Create: `HDiary/Configs/widget-debug.xcconfig`
- Create: `HDiary/Configs/widget-release.xcconfig`
- Create: `HDiary/Configs/unit-tests.xcconfig`
- Create: `HDiary/Configs/unit-tests-debug.xcconfig`
- Create: `HDiary/Configs/unit-tests-release.xcconfig`
- Create: `HDiary/Configs/ui-tests.xcconfig`
- Create: `HDiary/Configs/ui-tests-debug.xcconfig`
- Create: `HDiary/Configs/ui-tests-release.xcconfig`
- Modify: `HDiary.xcodeproj/project.pbxproj`

**Interfaces:**
- Consumes: target build configuration IDs:
  - Widget Debug `6072D3B82A6161DC0020B7AF`
  - Widget Release `6072D3B92A6161DC0020B7AF`
  - App Debug `60A4E2252A3DDCE3000E68A0`
  - App Release `60A4E2262A3DDCE3000E68A0`
  - Unit Tests Debug `60A4E2282A3DDCE3000E68A0`
  - Unit Tests Release `60A4E2292A3DDCE3000E68A0`
  - UI Tests Debug `60A4E22B2A3DDCE3000E68A0`
  - UI Tests Release `60A4E22C2A3DDCE3000E68A0`
- Produces: target settings resolved from target-specific xcconfig entry files.

- [ ] **Step 1: Create app target xcconfig files**

Create `HDiary/Configs/app.xcconfig`:

```xcconfig
#include "./base.xcconfig"

ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon
ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor
CODE_SIGN_ENTITLEMENTS = HDiary/HDiary.entitlements
DEAD_CODE_STRIPPING = YES
DEVELOPMENT_ASSET_PATHS = HDiary/Preview\ Content
ENABLE_HARDENED_RUNTIME = YES
ENABLE_PREVIEWS = YES
INFOPLIST_FILE = HDiary/Info.plist
INFOPLIST_KEY_UIApplicationSceneManifest_Generation[sdk=iphoneos*] = YES
INFOPLIST_KEY_UIApplicationSceneManifest_Generation[sdk=iphonesimulator*] = YES
INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents[sdk=iphoneos*] = YES
INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents[sdk=iphonesimulator*] = YES
INFOPLIST_KEY_UILaunchScreen_Generation[sdk=iphoneos*] = YES
INFOPLIST_KEY_UILaunchScreen_Generation[sdk=iphonesimulator*] = YES
INFOPLIST_KEY_UIStatusBarStyle[sdk=iphoneos*] = UIStatusBarStyleDefault
INFOPLIST_KEY_UIStatusBarStyle[sdk=iphonesimulator*] = UIStatusBarStyleDefault
INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight
INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight
LD_RUNPATH_SEARCH_PATHS = @executable_path/Frameworks
LD_RUNPATH_SEARCH_PATHS[sdk=macosx*] = @executable_path/../Frameworks
MACOSX_DEPLOYMENT_TARGET = 14.0
PRODUCT_NAME = HDiary
SDKROOT = auto
SUPPORTED_PLATFORMS = iphoneos iphonesimulator macosx
SWIFT_EMIT_LOC_STRINGS = YES
```

Create `HDiary/Configs/app-debug.xcconfig`:

```xcconfig
#include "./debug.xcconfig"
#include "./app.xcconfig"

PRODUCT_BUNDLE_IDENTIFIER = com.tiger.suzhou.HDiary-Debug
```

Create `HDiary/Configs/app-release.xcconfig`:

```xcconfig
#include "./release.xcconfig"
#include "./app.xcconfig"

PRODUCT_BUNDLE_IDENTIFIER = com.tiger.suzhou.HDiary
```

- [ ] **Step 2: Create widget target xcconfig files**

Create `HDiary/Configs/widget.xcconfig`:

```xcconfig
#include "./base.xcconfig"

ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor
ASSETCATALOG_COMPILER_WIDGET_BACKGROUND_COLOR_NAME = WidgetBackground
CODE_SIGN_ENTITLEMENTS = HDiaryWidgetExtension.entitlements
INFOPLIST_FILE = HDiaryWidget/Info.plist
INFOPLIST_KEY_CFBundleDisplayName = HDiaryWidget
INFOPLIST_KEY_NSHumanReadableCopyright =
LD_RUNPATH_SEARCH_PATHS = $(inherited) @executable_path/Frameworks @executable_path/../../Frameworks
PRODUCT_NAME = $(TARGET_NAME)
SDKROOT = iphoneos
SKIP_INSTALL = YES
SWIFT_EMIT_LOC_STRINGS = YES
```

Create `HDiary/Configs/widget-debug.xcconfig`:

```xcconfig
#include "./debug.xcconfig"
#include "./widget.xcconfig"

PRODUCT_BUNDLE_IDENTIFIER = com.tiger.suzhou.HDiary-Debug.HDiaryWidget
```

Create `HDiary/Configs/widget-release.xcconfig`:

```xcconfig
#include "./release.xcconfig"
#include "./widget.xcconfig"

PRODUCT_BUNDLE_IDENTIFIER = com.tiger.suzhou.HDiary.HDiaryWidget
VALIDATE_PRODUCT = YES
```

- [ ] **Step 3: Create unit test target xcconfig files**

Create `HDiary/Configs/unit-tests.xcconfig`:

```xcconfig
#include "./base.xcconfig"

BUNDLE_LOADER = $(TEST_HOST)
DEAD_CODE_STRIPPING = YES
MACOSX_DEPLOYMENT_TARGET = 13.4
PRODUCT_BUNDLE_IDENTIFIER = com.tiger.suzhou.HDiaryTests
PRODUCT_NAME = $(TARGET_NAME)
SDKROOT = auto
SUPPORTED_PLATFORMS = iphoneos iphonesimulator macosx
SWIFT_EMIT_LOC_STRINGS = NO
TEST_HOST = $(BUILT_PRODUCTS_DIR)/HDiary.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/HDiary
```

Create `HDiary/Configs/unit-tests-debug.xcconfig`:

```xcconfig
#include "./debug.xcconfig"
#include "./unit-tests.xcconfig"
```

Create `HDiary/Configs/unit-tests-release.xcconfig`:

```xcconfig
#include "./release.xcconfig"
#include "./unit-tests.xcconfig"
```

- [ ] **Step 4: Create UI test target xcconfig files**

Create `HDiary/Configs/ui-tests.xcconfig`:

```xcconfig
#include "./base.xcconfig"

DEAD_CODE_STRIPPING = YES
MACOSX_DEPLOYMENT_TARGET = 13.4
PRODUCT_BUNDLE_IDENTIFIER = com.tiger.suzhou.HDiaryUITests
PRODUCT_NAME = $(TARGET_NAME)
SDKROOT = auto
SUPPORTED_PLATFORMS = iphoneos iphonesimulator macosx
SWIFT_EMIT_LOC_STRINGS = NO
TEST_TARGET_NAME = HDiary
```

Create `HDiary/Configs/ui-tests-debug.xcconfig`:

```xcconfig
#include "./debug.xcconfig"
#include "./ui-tests.xcconfig"
```

Create `HDiary/Configs/ui-tests-release.xcconfig`:

```xcconfig
#include "./release.xcconfig"
#include "./ui-tests.xcconfig"
```

- [ ] **Step 5: Exclude new xcconfig files from file-system-synchronized app target membership**

In `HDiary.xcodeproj/project.pbxproj`, update the `membershipExceptions` list in exception set `60F3DD222CDDF1AF00C05BFB` so it contains exactly these config paths plus `Info.plist`:

```pbxproj
membershipExceptions = (
	Configs/app-debug.xcconfig,
	Configs/app-release.xcconfig,
	Configs/app.xcconfig,
	Configs/base.xcconfig,
	Configs/debug.xcconfig,
	Configs/release.xcconfig,
	Configs/ui-tests-debug.xcconfig,
	Configs/ui-tests-release.xcconfig,
	Configs/ui-tests.xcconfig,
	Configs/unit-tests-debug.xcconfig,
	Configs/unit-tests-release.xcconfig,
	Configs/unit-tests.xcconfig,
	Configs/widget-debug.xcconfig,
	Configs/widget-release.xcconfig,
	Configs/widget.xcconfig,
	Info.plist,
);
```

- [ ] **Step 6: Wire target build configurations to xcconfig entry files**

In `HDiary.xcodeproj/project.pbxproj`, add `baseConfigurationReferenceAnchor` and `baseConfigurationReferenceRelativePath` before each target `buildSettings` block:

```text
6072D3B82A6161DC0020B7AF Debug  -> Configs/widget-debug.xcconfig
6072D3B92A6161DC0020B7AF Release -> Configs/widget-release.xcconfig
60A4E2252A3DDCE3000E68A0 Debug  -> Configs/app-debug.xcconfig
60A4E2262A3DDCE3000E68A0 Release -> Configs/app-release.xcconfig
60A4E2282A3DDCE3000E68A0 Debug  -> Configs/unit-tests-debug.xcconfig
60A4E2292A3DDCE3000E68A0 Release -> Configs/unit-tests-release.xcconfig
60A4E22B2A3DDCE3000E68A0 Debug  -> Configs/ui-tests-debug.xcconfig
60A4E22C2A3DDCE3000E68A0 Release -> Configs/ui-tests-release.xcconfig
```

For each of the eight target build configurations, use this anchor:

```pbxproj
baseConfigurationReferenceAnchor = 60F3DCB92CDDF1AF00C05BFB /* HDiary */;
```

and replace the existing target `buildSettings = { ... };` block with:

```pbxproj
buildSettings = {
};
```

- [ ] **Step 7: Verify build settings after target-level migration**

Tool call:

```json
{
  "tool": "xcodebuildmcp-show_build_settings"
}
```

Expected output contains:

```text
PRODUCT_BUNDLE_IDENTIFIER = com.tiger.suzhou.HDiary-Debug
PRODUCT_NAME = HDiary
INFOPLIST_FILE = HDiary/Info.plist
CODE_SIGN_ENTITLEMENTS = HDiary/HDiary.entitlements
DEVELOPMENT_ASSET_PATHS = HDiary/Preview\ Content
```

- [ ] **Step 8: Build after target-level config migration**

Tool call:

```json
{
  "tool": "xcodebuildmcp-build_sim",
  "input": {
    "extraArgs": []
  }
}
```

Expected: build succeeds.

- [ ] **Step 9: Commit target-level config migration**

Run:

```bash
git add HDiary/Configs HDiary.xcodeproj/project.pbxproj
git commit -m "chore: move target build settings to xcconfig" -m "Co-authored-by: Copilot App <223556219+Copilot@users.noreply.github.com>"
```

Expected: one commit containing target xcconfig files and pbxproj wiring.

---

### Task 4: Extract Startup Data Maintenance into `HDiaryModel`

**Files:**
- Create: `HDiaryLibrary/Sources/HDiaryModel/ModelOperation/StartupDataMaintenanceService.swift`
- Create: `HDiaryLibrary/Tests/HDiaryModelTests/StartupDataMaintenanceServiceTests.swift`
- Modify: `HDiary/BaseTabView.swift`

**Interfaces:**
- Consumes: `ModelContext`, `HappyImage`, `MediaItem`, `Moment`, `Log`.
- Produces:
  - `@MainActor public struct StartupDataMaintenanceService`
  - `public func runLoggingFailures(in modelContext: ModelContext, deletedMomentRetention: TimeInterval = 60 * 60 * 24 * 30)`
  - `public func migrateLegacyImages(in modelContext: ModelContext) throws -> LegacyImageMigrationResult`
  - `public func updateMissingMediaStorageSizes(in modelContext: ModelContext) throws -> MediaStorageUpdateResult`
  - `public func cleanUpOrphanMediaItems(in modelContext: ModelContext) throws -> OrphanMediaCleanupResult`
  - `public func cleanUpDeletedMoments(in modelContext: ModelContext, deleteTimeThreshold: Date) throws -> DeletedMomentCleanupResult`

- [ ] **Step 1: Write failing tests**

Create `HDiaryLibrary/Tests/HDiaryModelTests/StartupDataMaintenanceServiceTests.swift`:

```swift
#if os(iOS)

  @testable import HDiaryModel
  import SwiftData
  import XCTest

  @MainActor
  final class StartupDataMaintenanceServiceTests: XCTestCase {
    private func makeContext() throws -> ModelContext {
      let configuration = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
      let container = try ModelContainer(for: Schema.hDiaryScheme, configurations: [configuration])
      return ModelContext(container)
    }

    func testMigrateLegacyImagesCreatesMediaItemsAndDeletesHappyImages() throws {
      let context = try makeContext()
      let moment = Moment.create(timestamp: Date())
      let legacyImage = HappyImage.create()
      moment.updateLegacyImages([legacyImage])
      context.insert(moment)
      context.insert(legacyImage)
      try context.save()

      let result = try StartupDataMaintenanceService().migrateLegacyImages(in: context)

      XCTAssertEqual(result.convertedLegacyImages, 1)
      XCTAssertEqual(result.deletedOrphanLegacyImages, 0)
      XCTAssertEqual(try context.fetchCount(FetchDescriptor<HappyImage>()), 0)
      XCTAssertEqual(try context.fetchCount(FetchDescriptor<MediaItem>()), 1)
      let mediaItem = try XCTUnwrap(try context.fetch(FetchDescriptor<MediaItem>()).first)
      XCTAssertNotNil(mediaItem.moment)
    }

    func testMigrateLegacyImagesDeletesOrphanHappyImages() throws {
      let context = try makeContext()
      context.insert(HappyImage.create())
      try context.save()

      let result = try StartupDataMaintenanceService().migrateLegacyImages(in: context)

      XCTAssertEqual(result.convertedLegacyImages, 0)
      XCTAssertEqual(result.deletedOrphanLegacyImages, 1)
      XCTAssertEqual(try context.fetchCount(FetchDescriptor<HappyImage>()), 0)
      XCTAssertEqual(try context.fetchCount(FetchDescriptor<MediaItem>()), 0)
    }

    func testCleanUpOrphanMediaItemsDeletesOnlyItemsWithoutMoment() throws {
      let context = try makeContext()
      let moment = Moment.create(timestamp: Date())
      let attachedMediaItem = MediaItem(
        data: Data([1]),
        moment: moment,
        mediaType: .image,
        pathExtension: "heic",
        thumbnailData150px: nil,
        thumbnailData500px: nil,
        thumbnailData1000px: nil
      )
      let orphanMediaItem = MediaItem(
        data: Data([2]),
        mediaType: .image,
        pathExtension: "heic",
        thumbnailData150px: nil,
        thumbnailData500px: nil,
        thumbnailData1000px: nil
      )
      context.insert(moment)
      context.insert(attachedMediaItem)
      context.insert(orphanMediaItem)
      try context.save()

      let result = try StartupDataMaintenanceService().cleanUpOrphanMediaItems(in: context)

      XCTAssertEqual(result.deletedMediaItemIDs, [orphanMediaItem.uuid])
      XCTAssertEqual(result.validMediaItemCount, 1)
      let remainingItems = try context.fetch(FetchDescriptor<MediaItem>())
      XCTAssertEqual(remainingItems.map(\.uuid), [attachedMediaItem.uuid])
    }

    func testCleanUpDeletedMomentsDeletesOnlyMarkedMomentsBeforeThreshold() throws {
      let context = try makeContext()
      let deletedMoment = Moment.create(timestamp: Date())
      deletedMoment.markAsDelete()
      let activeMoment = Moment.create(timestamp: Date())
      context.insert(deletedMoment)
      context.insert(activeMoment)
      try context.save()

      let result = try StartupDataMaintenanceService().cleanUpDeletedMoments(
        in: context,
        deleteTimeThreshold: Date.distantFuture
      )

      XCTAssertEqual(result.deletedMomentCount, 1)
      let remainingMoments = try context.fetch(FetchDescriptor<Moment>())
      XCTAssertEqual(remainingMoments.map(\.uuid), [activeMoment.uuid])
    }
  }

#endif
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```bash
HTTP_PROXY=http://127.0.0.1:1082 HTTPS_PROXY=http://127.0.0.1:1082 ALL_PROXY=http://127.0.0.1:1082 http_proxy=http://127.0.0.1:1082 https_proxy=http://127.0.0.1:1082 all_proxy=http://127.0.0.1:1082 NO_PROXY=localhost,127.0.0.1,::1 no_proxy=localhost,127.0.0.1,::1 GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=safe.bareRepository GIT_CONFIG_VALUE_0=all swift test --package-path HDiaryLibrary --filter StartupDataMaintenanceServiceTests
```

Expected: compile fails because `StartupDataMaintenanceService` is not defined.

- [ ] **Step 3: Implement `StartupDataMaintenanceService`**

Create `HDiaryLibrary/Sources/HDiaryModel/ModelOperation/StartupDataMaintenanceService.swift`:

```swift
#if os(iOS)

  import Foundation
  import HDiaryConstants
  import SwiftData

  @MainActor
  public struct StartupDataMaintenanceService {
    public struct LegacyImageMigrationResult: Equatable {
      public let convertedLegacyImages: Int
      public let deletedOrphanLegacyImages: Int
    }

    public struct MediaStorageUpdateResult: Equatable {
      public let updatedMediaItemIDs: [UUID]
    }

    public struct OrphanMediaCleanupResult: Equatable {
      public let deletedMediaItemIDs: [UUID]
      public let validMediaItemCount: Int
    }

    public struct DeletedMomentCleanupResult: Equatable {
      public let deletedMomentCount: Int
    }

    public init() {}

    public func runLoggingFailures(
      in modelContext: ModelContext,
      deletedMomentRetention: TimeInterval = 60 * 60 * 24 * 30
    ) {
      do {
        let result = try migrateLegacyImages(in: modelContext)
        Log.DB.migration.info("legacy image migration successed, converted: \(result.convertedLegacyImages, privacy: .public), deleted orphan legacy images: \(result.deletedOrphanLegacyImages, privacy: .public)")
      }
      catch {
        Log.DB.migration.error("Migrate legacy image fail \(error)")
      }

      do {
        let result = try updateMissingMediaStorageSizes(in: modelContext)
        Log.DB.migration.info("media item storage size update finished, updated count: \(result.updatedMediaItemIDs.count, privacy: .public)")
      }
      catch {
        Log.DB.migration.error("media item update storage size fail \(error)")
      }

      do {
        let result = try cleanUpOrphanMediaItems(in: modelContext)
        Log.data.info("Finish to clean up data, deleted media items: \(result.deletedMediaItemIDs, privacy: .public), valid media items: \(result.validMediaItemCount, privacy: .public)")
      }
      catch {
        Log.data.error("Failed to clean up data: \(error)")
      }

      do {
        let deleteTimeThreshold = Date(timeIntervalSinceNow: -deletedMomentRetention)
        let result = try cleanUpDeletedMoments(in: modelContext, deleteTimeThreshold: deleteTimeThreshold)
        Log.data.info("Finish to clean up deleted moments, deleted moments count: \(result.deletedMomentCount, privacy: .public)")
      }
      catch {
        Log.data.error("Failed to clean up deleted moments: \(error)")
      }
    }

    public func migrateLegacyImages(in modelContext: ModelContext) throws -> LegacyImageMigrationResult {
      let legacyImages = try modelContext.fetch(FetchDescriptor<HappyImage>())
      var convertedLegacyImages = 0
      var deletedOrphanLegacyImages = 0

      for image in legacyImages {
        if image.moment != nil {
          image.updateThumbnail()
          let mediaItem = MediaItem(image)
          mediaItem.moment = image.moment
          modelContext.insert(mediaItem)
          modelContext.delete(image)
          convertedLegacyImages += 1
          Log.DB.migration.info("update thumbnail for image \(image.uuid)")
        }
        else {
          modelContext.delete(image)
          deletedOrphanLegacyImages += 1
          Log.DB.migration.info("delete image  \(image.uuid) because no moments")
        }
      }

      try modelContext.save()
      return LegacyImageMigrationResult(
        convertedLegacyImages: convertedLegacyImages,
        deletedOrphanLegacyImages: deletedOrphanLegacyImages
      )
    }

    public func updateMissingMediaStorageSizes(in modelContext: ModelContext) throws -> MediaStorageUpdateResult {
      var updatedMediaItemIDs: [UUID] = []
      try modelContext.enumerate(
        FetchDescriptor<MediaItem>(),
        batchSize: 10,
        allowEscapingMutations: true
      ) { mediaItem in
        if mediaItem.storageSize == nil {
          mediaItem.updateStorageSizeIfNeeded()
          updatedMediaItemIDs.append(mediaItem.uuid)
          Log.DB.migration.info("media item \(mediaItem.uuid) update storage size successed")
        }
      }
      try modelContext.save()
      return MediaStorageUpdateResult(updatedMediaItemIDs: updatedMediaItemIDs)
    }

    public func cleanUpOrphanMediaItems(in modelContext: ModelContext) throws -> OrphanMediaCleanupResult {
      Log.data.info("Start to clean up data")
      var deletedMediaItemIDs: [UUID] = []
      var validMediaItemIDs: [UUID] = []

      try modelContext.enumerate(FetchDescriptor<MediaItem>(), batchSize: 5) { mediaItem in
        if mediaItem.moment == nil {
          deletedMediaItemIDs.append(mediaItem.uuid)
          Log.data.info("delete media item \(mediaItem.uuid, privacy: .public)")
          modelContext.delete(mediaItem)
        }
        else {
          validMediaItemIDs.append(mediaItem.uuid)
        }
      }

      try modelContext.save()
      return OrphanMediaCleanupResult(
        deletedMediaItemIDs: deletedMediaItemIDs,
        validMediaItemCount: validMediaItemIDs.count
      )
    }

    public func cleanUpDeletedMoments(
      in modelContext: ModelContext,
      deleteTimeThreshold: Date
    ) throws -> DeletedMomentCleanupResult {
      Log.data.info("Start to clean up deleted moments")
      let momentsCountBeforeDeletion = try modelContext.fetchCount(FetchDescriptor<Moment>())
      let predicate = #Predicate<Moment> {
        if $0.markedAsDelete {
          if let markedAsDeleteDate = $0.markedAsDeleteDate {
            return markedAsDeleteDate < deleteTimeThreshold
          }
          else {
            return false
          }
        }
        else {
          return false
        }
      }
      try modelContext.delete(model: Moment.self, where: predicate)
      try modelContext.save()
      let momentsCountAfterDeletion = try modelContext.fetchCount(FetchDescriptor<Moment>())
      return DeletedMomentCleanupResult(
        deletedMomentCount: momentsCountBeforeDeletion - momentsCountAfterDeletion
      )
    }
  }

#endif
```

- [ ] **Step 4: Replace inline maintenance calls in `BaseTabView`**

In `HDiary/BaseTabView.swift`, keep existing imports. Replace this block inside `.onAppear`:

```swift
Log.common.info("Performing startup task")
migrationDB()
updateMediaInfo()
cleanUpData()
modelContext.undoManager = undoManager
```

with:

```swift
Log.common.info("Performing startup task")
StartupDataMaintenanceService().runLoggingFailures(in: modelContext)
modelContext.undoManager = undoManager
```

Then delete the private methods `migrationDB()`, `updateMediaInfo()`, and `cleanUpData()` from `BaseTabView`.

- [ ] **Step 5: Run focused package tests**

Run:

```bash
HTTP_PROXY=http://127.0.0.1:1082 HTTPS_PROXY=http://127.0.0.1:1082 ALL_PROXY=http://127.0.0.1:1082 http_proxy=http://127.0.0.1:1082 https_proxy=http://127.0.0.1:1082 all_proxy=http://127.0.0.1:1082 NO_PROXY=localhost,127.0.0.1,::1 no_proxy=localhost,127.0.0.1,::1 GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=safe.bareRepository GIT_CONFIG_VALUE_0=all swift test --package-path HDiaryLibrary --filter StartupDataMaintenanceServiceTests
```

Expected: `StartupDataMaintenanceServiceTests` passes.

- [ ] **Step 6: Build app after startup service extraction**

Tool call:

```json
{
  "tool": "xcodebuildmcp-build_sim",
  "input": {
    "extraArgs": []
  }
}
```

Expected: build succeeds.

- [ ] **Step 7: Commit startup service extraction**

Run:

```bash
git add HDiary/BaseTabView.swift HDiaryLibrary/Sources/HDiaryModel/ModelOperation/StartupDataMaintenanceService.swift HDiaryLibrary/Tests/HDiaryModelTests/StartupDataMaintenanceServiceTests.swift
git commit -m "refactor: move startup data maintenance to package" -m "Co-authored-by: Copilot App <223556219+Copilot@users.noreply.github.com>"
```

Expected: one commit containing service extraction, tests, and `BaseTabView` cleanup.

---

### Task 5: Move Search Model Logic into `HDiarySearch`

**Files:**
- Modify: `HDiaryLibrary/Package.swift`
- Move: `HDiary/Search/Model/SearchEngine.swift` -> `HDiaryLibrary/Sources/HDiarySearch/SearchEngine.swift`
- Move: `HDiary/Search/Model/SearchRecommendEngine.swift` -> `HDiaryLibrary/Sources/HDiarySearch/SearchRecommendEngine.swift`
- Move: `HDiary/Search/Model/SearchViewModel.swift` -> `HDiaryLibrary/Sources/HDiarySearch/SearchViewModel.swift`
- Delete: `HDiary/Search/Model/SearchableItem.swift`
- Create: `HDiaryLibrary/Tests/HDiarySearchTests/SearchEngineTests.swift`
- Modify: `HDiary/BaseTabView.swift`
- Modify: `HDiary/Common/Navigation/AppEnvironments.swift`
- Modify: `HDiary/Search/View/SearchModifier.swift`
- Modify: `HDiary/Search/View/SearchView.swift`
- Modify: `HDiary/Moments/MomentList/MomentTab.swift`
- Modify: `HDiary.xcodeproj/project.pbxproj`
- Update: `HDiaryLibrary/Package.resolved`
- Update: `HDiary.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`

**Interfaces:**
- Consumes: existing `SearchEngine`, `SearchRecommendEngine`, `SearchViewModel`, `Moment`, `HDiaryContainer`, `Log.search`.
- Produces:
  - SwiftPM product `.library(name: "HDiarySearch", targets: ["HDiarySearch"])`
  - target `HDiarySearch`
  - `@MainActor @Observable public final class SearchViewModel`
  - app imports `HDiarySearch` instead of relying on same-target search model files.

- [ ] **Step 1: Update `HDiaryLibrary/Package.swift`**

Edit `HDiaryLibrary/Package.swift` so:

1. `products` includes:

```swift
    .library(
      name: "HDiarySearch",
      targets: ["HDiarySearch"]
    ),
```

2. `dependencies` includes:

```swift
    .package(url: "https://github.com/apple/swift-atomics.git", from: "1.2.0"),
```

3. `targets` includes:

```swift
    .target(
      name: "HDiarySearch",
      dependencies: [
        "HDiaryConstants",
        "HDiaryModel",
        .product(name: "Atomics", package: "swift-atomics"),
      ]
    ),
    .testTarget(
      name: "HDiarySearchTests",
      dependencies: [
        "HDiarySearch",
        "HDiaryModel",
      ]
    ),
```

Place `HDiarySearch` after `HDiaryModel` and before `HDiaryConstants` in the file to keep domain targets grouped.

- [ ] **Step 2: Move search files**

Run:

```bash
mkdir -p HDiaryLibrary/Sources/HDiarySearch
git mv HDiary/Search/Model/SearchEngine.swift HDiaryLibrary/Sources/HDiarySearch/SearchEngine.swift
git mv HDiary/Search/Model/SearchRecommendEngine.swift HDiaryLibrary/Sources/HDiarySearch/SearchRecommendEngine.swift
git mv HDiary/Search/Model/SearchViewModel.swift HDiaryLibrary/Sources/HDiarySearch/SearchViewModel.swift
git rm HDiary/Search/Model/SearchableItem.swift
```

Expected:

```text
HDiary/Search/Model/SearchableItem.swift removed
HDiaryLibrary/Sources/HDiarySearch/SearchEngine.swift exists
HDiaryLibrary/Sources/HDiarySearch/SearchRecommendEngine.swift exists
HDiaryLibrary/Sources/HDiarySearch/SearchViewModel.swift exists
```

- [ ] **Step 3: Make moved search model compile as a package API**

In all three moved files, wrap contents with `#if os(iOS)` and `#endif`.

In `HDiaryLibrary/Sources/HDiarySearch/SearchViewModel.swift`, change the public API surface to:

```swift
#if os(iOS)

  import Atomics
  import Foundation
  import HDiaryConstants
  import HDiaryModel
  import Observation
  import SwiftData

  @MainActor
  @Observable public final class SearchViewModel {
    public var queryText = ""

    private enum Constants {
      static let throttleDurationInMs: UInt64 = 250
    }

    public enum State {
      case idle
      case recommend(moments: [Moment])
      case searching(queryText: String)
      case searchSucceed(moments: [Moment])
      case searchError(error: Error)
    }

    private var searchTask: Task<Void, Never>?
    public private(set) var state: State = .idle

    private let container: ModelContainer
    private let recommendEngine: SearchRecommendEngine
    private let searchEngine: SearchEngine

    public init() {
      self.container = HDiaryContainer.getCurrentContainer()
      self.recommendEngine = SearchRecommendEngine(modelContainer: container)
      self.searchEngine = SearchEngine(modelContainer: container)
    }

    public func reset() {
      state = .idle
      startRecommend()
    }

    public func startRecommend() {
      Task {
        Log.search.info("Start Recommend")
        let recommendedMoments = await Task.detached {
          await self.recommendEngine.getRecommendedMoment()
        }.value

        if self.queryText.isEmpty {
          self.state = .recommend(moments: recommendedMoments)
        }
      }
    }

    public func search() async {
      searchTask?.cancel()
      guard !queryText.isEmpty else {
        reset()
        Log.search.info("Query text is empty, reset")
        return
      }
      Log.search.info("Searching for: \(self.queryText)")

      let query = self.queryText
      state = .searching(queryText: query)

      searchTask = Task {
        let isCancelled = ManagedAtomic<Bool>(false)
        await withTaskCancellationHandler {
          do {
            try await Task.sleep(nanoseconds: Constants.throttleDurationInMs * NSEC_PER_MSEC)
          }
          catch {
            Log.search.debug("Search cancelled before actual search for \(query)")
            return
          }

          let clock = SuspendingClock()
          let searchStartTime = clock.now

          do {
            Log.search.info("Search actual logic started for \(query)")

            let matchedMoment = try await Task.detached {
              try await self.searchEngine.searchMoment(for: query, isCancelled: isCancelled)
            }.value

            let searchEndTime = clock.now

            let searchDuration = searchStartTime.duration(to: searchEndTime)
            try Task.checkCancellation()

            state = .searchSucceed(moments: matchedMoment)
            Log.search.info("Search finished  after \(searchDuration.formatted(.units(allowed: [.seconds, .milliseconds])), privacy: .public) for \(query), result count: \(matchedMoment.count, privacy: .public)")
          }
          catch {
            let searchEndTime = clock.now
            let searchDuration = searchStartTime.duration(to: searchEndTime)
            if error is CancellationError {
              Log.search.info("Search cancelled for \(query) after \(searchDuration.formatted(.units(allowed: [.seconds, .milliseconds])), privacy: .public)")
            }
            else if query != self.queryText {
              Log.search.info("Search cancelled because query changed for \(query) after \(searchDuration.formatted(.units(allowed: [.seconds, .milliseconds])), privacy: .public)")
            }
            else {
              Log.search.error("Failed to fetch moments for \(query): \(error) after \(searchDuration.formatted(.units(allowed: [.seconds, .milliseconds])), privacy: .public)")
              state = .searchError(error: error)
            }
          }

        } onCancel: {
          isCancelled.store(true, ordering: .relaxed)
        }
      }
    }
  }

#endif
```

Keep `SearchEngine` and `SearchRecommendEngine` internal. Their existing declarations can remain `actor SearchEngine` and `actor SearchRecommendEngine` because only `SearchViewModel` consumes them.

- [ ] **Step 4: Add search engine tests**

Create `HDiaryLibrary/Tests/HDiarySearchTests/SearchEngineTests.swift`:

```swift
#if os(iOS)

  @testable import HDiarySearch
  @testable import HDiaryModel
  import Atomics
  import SwiftData
  import XCTest

  final class SearchEngineTests: XCTestCase {
    private func makeContainer() throws -> ModelContainer {
      let configuration = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
      return try ModelContainer(for: Schema.hDiaryScheme, configurations: [configuration])
    }

    func testSearchMomentMatchesTitleAndContent() async throws {
      let container = try makeContainer()
      let context = ModelContext(container)

      let titleMatch = Moment.create(timestamp: Date(timeIntervalSince1970: 2))
      titleMatch.updateTitle("needle title")
      titleMatch.updateContent("body")

      let contentMatch = Moment.create(timestamp: Date(timeIntervalSince1970: 1))
      contentMatch.updateTitle("title")
      contentMatch.updateContent("needle body")

      let nonMatch = Moment.create(timestamp: Date(timeIntervalSince1970: 3))
      nonMatch.updateTitle("title")
      nonMatch.updateContent("body")

      context.insert(titleMatch)
      context.insert(contentMatch)
      context.insert(nonMatch)
      try context.save()

      let engine = SearchEngine(modelContainer: container)
      let results = try await engine.searchMoment(
        for: "needle",
        isCancelled: ManagedAtomic<Bool>(false)
      )

      XCTAssertEqual(results.map(\.uuid), [titleMatch.uuid, contentMatch.uuid])
    }

    func testSearchMomentThrowsCancellationBeforeFetch() async throws {
      let container = try makeContainer()
      let engine = SearchEngine(modelContainer: container)
      let isCancelled = ManagedAtomic<Bool>(true)

      do {
        _ = try await engine.searchMoment(for: "needle", isCancelled: isCancelled)
        XCTFail("Expected CancellationError")
      }
      catch is CancellationError {
        XCTAssertTrue(true)
      }
    }
  }

#endif
```

- [ ] **Step 5: Run package resolve and focused tests**

Run:

```bash
HTTP_PROXY=http://127.0.0.1:1082 HTTPS_PROXY=http://127.0.0.1:1082 ALL_PROXY=http://127.0.0.1:1082 http_proxy=http://127.0.0.1:1082 https_proxy=http://127.0.0.1:1082 all_proxy=http://127.0.0.1:1082 NO_PROXY=localhost,127.0.0.1,::1 no_proxy=localhost,127.0.0.1,::1 GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=safe.bareRepository GIT_CONFIG_VALUE_0=all swift package --package-path HDiaryLibrary resolve

HTTP_PROXY=http://127.0.0.1:1082 HTTPS_PROXY=http://127.0.0.1:1082 ALL_PROXY=http://127.0.0.1:1082 http_proxy=http://127.0.0.1:1082 https_proxy=http://127.0.0.1:1082 all_proxy=http://127.0.0.1:1082 NO_PROXY=localhost,127.0.0.1,::1 no_proxy=localhost,127.0.0.1,::1 GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=safe.bareRepository GIT_CONFIG_VALUE_0=all swift test --package-path HDiaryLibrary --filter SearchEngineTests
```

Expected: dependency resolution succeeds and `SearchEngineTests` passes.

- [ ] **Step 6: Import `HDiarySearch` from app integration files**

Add `import HDiarySearch` to these files:

```text
HDiary/BaseTabView.swift
HDiary/Common/Navigation/AppEnvironments.swift
HDiary/Search/View/SearchModifier.swift
HDiary/Search/View/SearchView.swift
HDiary/Moments/MomentList/MomentTab.swift
```

Do not change the SwiftUI view behavior. The existing `SearchViewModel()` calls and `@Environment(SearchViewModel.self)` declarations should remain the same.

- [ ] **Step 7: Wire `HDiarySearch` into the app target and remove direct `Atomics`**

In `HDiary.xcodeproj/project.pbxproj`:

1. Add a build file entry to `PBXBuildFile section`:

```pbxproj
60F100002E00000100000001 /* HDiarySearch in Frameworks */ = {isa = PBXBuildFile; productRef = 60F100012E00000100000001 /* HDiarySearch */; };
```

2. Add `60F100002E00000100000001 /* HDiarySearch in Frameworks */` to app target framework phase `60A4E1F92A3DDCE1000E68A0 /* Frameworks */`.

3. Add `60F100012E00000100000001 /* HDiarySearch */` to app target `packageProductDependencies` under `60A4E1FB2A3DDCE1000E68A0 /* HDiary */`.

4. Add product dependency entry to `XCSwiftPackageProductDependency section`:

```pbxproj
60F100012E00000100000001 /* HDiarySearch */ = {
	isa = XCSwiftPackageProductDependency;
	productName = HDiarySearch;
};
```

5. Remove app target direct `Atomics` wiring because `Atomics` is now consumed by `HDiarySearch`:

```pbxproj
604DC3242DB3992A0088ACF9 /* Atomics in Frameworks */
604DC3232DB3992A0088ACF9 /* Atomics */
604DC3222DB3981B0088ACF9 /* XCRemoteSwiftPackageReference "swift-atomics" */
```

Remove those IDs from the `PBXBuildFile section`, app Frameworks list, `PBXProject.packageReferences`, app `packageProductDependencies`, `XCRemoteSwiftPackageReference section`, and `XCSwiftPackageProductDependency section`.

- [ ] **Step 8: Resolve Xcode packages and build**

Tool call:

```json
{
  "tool": "xcodebuildmcp-build_sim",
  "input": {
    "extraArgs": []
  }
}
```

Expected: app builds and Xcode resolves `HDiarySearch` through local `HDiaryLibrary`.

- [ ] **Step 9: Run full package tests**

Run:

```bash
HTTP_PROXY=http://127.0.0.1:1082 HTTPS_PROXY=http://127.0.0.1:1082 ALL_PROXY=http://127.0.0.1:1082 http_proxy=http://127.0.0.1:1082 https_proxy=http://127.0.0.1:1082 all_proxy=http://127.0.0.1:1082 NO_PROXY=localhost,127.0.0.1,::1 no_proxy=localhost,127.0.0.1,::1 GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=safe.bareRepository GIT_CONFIG_VALUE_0=all swift test --package-path HDiaryLibrary
```

Expected: all `HDiaryLibrary` tests pass.

- [ ] **Step 10: Commit search package migration**

Run:

```bash
git add HDiaryLibrary/Package.swift HDiaryLibrary/Package.resolved HDiaryLibrary/Sources/HDiarySearch HDiaryLibrary/Tests/HDiarySearchTests HDiary/BaseTabView.swift HDiary/Common/Navigation/AppEnvironments.swift HDiary/Search HDiary/Moments/MomentList/MomentTab.swift HDiary.xcodeproj/project.pbxproj HDiary.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
git commit -m "refactor: move search model to package" -m "Co-authored-by: Copilot App <223556219+Copilot@users.noreply.github.com>"
```

Expected: one commit containing the `HDiarySearch` package target, tests, app imports, and Xcode product dependency changes.

---

### Task 6: Final Verification and Migration Inventory

**Files:**
- Read: `HDiary.xcodeproj/project.pbxproj`
- Read: `HDiary/Configs/*.xcconfig`
- Read: `HDiaryLibrary/Package.swift`
- No required file modifications.

**Interfaces:**
- Consumes: all previous task outputs.
- Produces: verified first-wave migration with clean working tree.

- [ ] **Step 1: Check migrated build settings are no longer duplicated in target buildSettings**

Run:

```bash
rg "PRODUCT_BUNDLE_IDENTIFIER|INFOPLIST_FILE|CODE_SIGN_ENTITLEMENTS|DEVELOPMENT_TEAM|SWIFT_VERSION|IPHONEOS_DEPLOYMENT_TARGET|CURRENT_PROJECT_VERSION|MARKETING_VERSION" HDiary.xcodeproj/project.pbxproj
```

Expected: no matches inside `buildSettings = { ... };` blocks for app/widget/test target configurations. Matches inside `baseConfigurationReferenceRelativePath`, package metadata, or comments are acceptable only if they are not target build setting assignments.

- [ ] **Step 2: Confirm app target no longer imports Atomics**

Run:

```bash
rg "import Atomics|ManagedAtomic" HDiary --glob "*.swift"
```

Expected:

```text
```

- [ ] **Step 3: Confirm search model files are package-owned**

Run:

```bash
test -f HDiaryLibrary/Sources/HDiarySearch/SearchEngine.swift
test -f HDiaryLibrary/Sources/HDiarySearch/SearchRecommendEngine.swift
test -f HDiaryLibrary/Sources/HDiarySearch/SearchViewModel.swift
test ! -e HDiary/Search/Model/SearchEngine.swift
test ! -e HDiary/Search/Model/SearchRecommendEngine.swift
test ! -e HDiary/Search/Model/SearchViewModel.swift
test ! -e HDiary/Search/Model/SearchableItem.swift
```

Expected: command exits with status 0.

- [ ] **Step 4: Count app/package Swift files for migration inventory**

Run:

```bash
find HDiary HDiaryWidget HDiaryLibrary/Sources HSharedCode/Sources -name '*.swift' \
  | awk -F/ '{ if ($1=="HDiaryLibrary" || $1=="HSharedCode") key=$1"/"$2; else key=$1 } {count[key]++} END {for (k in count) print count[k], k}' \
  | sort -nr
```

Expected: `HDiaryLibrary/Sources` count increased by at least 4 files compared with the baseline, and `HDiary` count decreased by at least 4 files.

- [ ] **Step 5: Run final package tests**

Run:

```bash
HTTP_PROXY=http://127.0.0.1:1082 HTTPS_PROXY=http://127.0.0.1:1082 ALL_PROXY=http://127.0.0.1:1082 http_proxy=http://127.0.0.1:1082 https_proxy=http://127.0.0.1:1082 all_proxy=http://127.0.0.1:1082 NO_PROXY=localhost,127.0.0.1,::1 no_proxy=localhost,127.0.0.1,::1 GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=safe.bareRepository GIT_CONFIG_VALUE_0=all swift test --package-path HDiaryLibrary

HTTP_PROXY=http://127.0.0.1:1082 HTTPS_PROXY=http://127.0.0.1:1082 ALL_PROXY=http://127.0.0.1:1082 http_proxy=http://127.0.0.1:1082 https_proxy=http://127.0.0.1:1082 all_proxy=http://127.0.0.1:1082 NO_PROXY=localhost,127.0.0.1,::1 no_proxy=localhost,127.0.0.1,::1 GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=safe.bareRepository GIT_CONFIG_VALUE_0=all swift test --package-path HSharedCode
```

Expected: both package test suites pass.

- [ ] **Step 6: Run final app build**

Tool call:

```json
{
  "tool": "xcodebuildmcp-build_sim",
  "input": {
    "extraArgs": []
  }
}
```

Expected: build succeeds.

- [ ] **Step 7: Run simulator test suite**

Tool call:

```json
{
  "tool": "xcodebuildmcp-test_sim",
  "input": {
    "extraArgs": [],
    "progress": true
  }
}
```

Expected: tests pass for scheme `HDiary`.

- [ ] **Step 8: Confirm working tree is clean**

Run:

```bash
git --no-pager status --short
```

Expected:

```text
```

If `Package.resolved` changed during final verification after Task 5 commit, commit only those resolved-file changes:

```bash
git add HDiaryLibrary/Package.resolved HDiary.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
git commit -m "chore: update resolved package pins" -m "Co-authored-by: Copilot App <223556219+Copilot@users.noreply.github.com>"
```
