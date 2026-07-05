# Swift Package Product 迁移设计

## 背景

当前 `HDiary.xcodeproj` 通过 file system synchronized groups 直接拥有 `HDiary`、`HDiaryWidget`、`HDiaryTests`、`HDiaryUITests` 目录下的 Swift 源码；同时 app 已经依赖 `HDiaryLibrary` 和 `HSharedCode` 中的多个 Swift Package products。

本次迁移的目标是把 project 直接拥有的大部分 Swift 源码按目录迁入现有 `HDiaryLibrary`，并让 app/widget 通过 package products 使用这些实现。用户确认选择真正的 package product 迁移，并接受为 module 边界所必需的 `import`、`public`、`@main` shim、test import 等 Swift 修改。

## 目标

- 将 `HDiary` app 的业务、UI、导航、设置、Moments、Library、Search glue 等 Swift 源码迁入 `HDiaryLibrary/Sources/HDiaryAppFeature`。
- 将 `HDiaryWidget` 的 widget 实现 Swift 源码迁入 `HDiaryLibrary/Sources/HDiaryWidgetFeature`。
- 将 `HDiaryTests` 的单元测试迁入 `HDiaryLibrary/Tests/HDiaryAppFeatureTests`。
- 将 `HDiaryUITests` 的 Swift 文件物理迁入 `HDiaryLibrary/UITests/HDiaryUITests`，但仍由 Xcode UI test target 编译和运行。
- 让 `HDiary` 和 `HDiaryWidgetExtension` Xcode targets 只保留最小 `@main` shim，并链接新增 package products。
- 保持业务逻辑、UI 行为、数据流和资源 bundle 语义不变。

## 非目标

- 不迁移 app/widget 的 `Info.plist`、entitlements、xcconfig、test plan、StoreKit、asset catalogs、AppIcon、app/widget `Localizable.xcstrings`。
- 不把迁移顺便扩展成业务重构、UI 调整、资源模块化或访问级别大改。
- 不以 `swift test` 作为新增 app/widget feature targets 的主验证入口，因为这些 targets 依赖 UIKit、WidgetKit、PhotosUI、SwiftData 等 iOS-only API。

## Target 架构

### `HDiaryAppFeature`

新增 `HDiaryLibrary` library product/target `HDiaryAppFeature`。它承载从 `HDiary` 迁出的 Swift 源码，依赖：

- `HDiaryConstants`
- `HDiaryModel`
- `HDiarySearch`
- `HDiaryIAP`
- `HSharedCode` 中的 `HLocalization`、`HFoundation`、`HUIComponent`、`HMedia`
- `SFSafeSymbols`

原 app 入口文件迁入 package 后去掉 `@main`，改为 package 内公开入口类型，例如 `public struct HDiaryFeatureApp: App`。`HDiary` Xcode target 新增一个最小 shim：

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

package 内部的 views、models、helpers 尽量保持 internal；只暴露 shim 需要访问的入口类型和 initializer。

### `HDiaryWidgetFeature`

新增 `HDiaryLibrary` library product/target `HDiaryWidgetFeature`。它承载从 `HDiaryWidget` 迁出的 Swift 源码，依赖 `HDiaryConstants` 和 `HDiaryModel`。原 widget bundle 入口迁入 package 后去掉 `@main`，改为公开的 widget bundle 类型，例如 `public struct HDiaryWidgetFeatureBundle: WidgetBundle`。

`HDiaryWidgetExtension` Xcode target 新增一个最小 shim：

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

### Tests

`HDiaryTests` 的 Swift 文件迁入 `HDiaryLibrary/Tests/HDiaryAppFeatureTests`，测试 target 依赖 `HDiaryAppFeature`。原来的 `@testable import HDiary` 改为 `@testable import HDiaryAppFeature`。

`HDiary/HDiary.xctestplan` 改为引用 `HDiaryLibrary` 中的 `HDiaryAppFeatureTests` package test target，并保留已有 `HDiaryConstantsTests`、`HDiaryIAPTests`、`HDiaryModelTests`、`HDiarySearchTests`。

`HDiaryUITests` 是 XCUITest 例外：为了保持 UI test discovery、scheme 运行方式和 app-under-test 关系，它仍由 Xcode UI test target 拥有。实现上把 Swift 文件物理移动到 `HDiaryLibrary/UITests/HDiaryUITests`，并把 Xcode project 的 UI test synchronized root 更新到该目录。

## 文件迁移

迁移使用目录级 `git mv`，保留相对目录结构，便于 review 中识别为移动：

| 来源 | 目标 |
| --- | --- |
| `HDiary/**/*.swift` | `HDiaryLibrary/Sources/HDiaryAppFeature/...` |
| `HDiaryWidget/**/*.swift` | `HDiaryLibrary/Sources/HDiaryWidgetFeature/...` |
| `HDiaryTests/**/*.swift` | `HDiaryLibrary/Tests/HDiaryAppFeatureTests/...` |
| `HDiaryUITests/**/*.swift` | `HDiaryLibrary/UITests/HDiaryUITests/...` |

迁移后 `HDiary` 和 `HDiaryWidget` 目录继续保存 Xcode target 配置和资源，并分别只新增一个 app/widget shim Swift 文件。`HDiaryTests` 不再作为 project 直接源码目录；如无兼容需要，可从 test plan 和 project 直接 test source ownership 中移除。

## Project 和 Package 变更

`HDiaryLibrary/Package.swift` 增加：

- `HDiaryAppFeature` product/target。
- `HDiaryWidgetFeature` product/target。
- `HDiaryAppFeatureTests` test target。
- `SFSafeSymbols` dependency，如果 `HDiaryAppFeature` 中的迁移代码继续 import 它。

`HDiary.xcodeproj/project.pbxproj` 调整：

- `HDiary` app target 链接 `HDiaryAppFeature` product。
- `HDiaryWidgetExtension` target 链接 `HDiaryWidgetFeature` product。
- app/widget target 的 synchronized root 中不再包含迁移前的大量 Swift 源码，仅保留 target 配置、资源和 shim。
- UI test target 的 synchronized root 指向 `HDiaryLibrary/UITests/HDiaryUITests`。

`HDiary/HDiary.xctestplan` 调整：

- 用 `HDiaryAppFeatureTests` package test target 替代 project-owned `HDiaryTests`。
- 保留现有 package test targets。

## 资源策略

资源按 target 语义保留在 Xcode project 中：

- `Info.plist`、entitlements、xcconfig 属于 build settings 和 signing/configuration，不迁入 package。
- `HDiary.xctestplan` 和 `IAP/HDiary.storekit` 属于 Xcode scheme/test/StoreKit 配置，不迁入 package。
- app/widget asset catalogs、AppIcon 和 `Localizable.xcstrings` 留在原 target，避免改动 `Bundle.main`、SwiftUI localization 或 asset lookup 行为。

如果后续要做资源 package 化，应单独设计，并显式处理 `Bundle.module`、localization bundle、asset bundle 的行为变化。

## 验证策略

验证以 Xcode iOS Simulator 为准：

- 迁移前记录 baseline：`HDiary` scheme build/test，`HDiaryWidgetExtension` scheme build。
- 迁移后重复相同验证，确保 app、widget、package tests、UI tests 仍可通过现有 Xcode flow。
- 检查 `git diff --summary` 和 `git status`，确认迁移的 Swift 文件主要表现为 renames/moves；入口和 test import 等必要 module-boundary 修改可以表现为内容修改。

## 风险和处理

- **访问级别错误**：只补入口 API、shim 访问、testable import 所需的最小 `public`/`init`，不把整批 views/helpers 改成 public。
- **依赖遗漏**：优先在 `Package.swift` target dependencies 中补齐已存在 products 或现有 external package，不复制代码。
- **资源行为变化**：因为本设计不迁移 app/widget resources，遇到资源相关问题时优先保持 `Bundle.main`/target resource 行为，而不是引入 `Bundle.module`。
- **UI tests package 化限制**：UI tests 保持 Xcode UI test target 语义；只迁移物理路径，不改变测试执行模型。
