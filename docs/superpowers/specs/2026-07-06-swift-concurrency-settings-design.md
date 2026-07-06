# Swift 版本与并发设置设计

## 背景

项目当前包含一个 Xcode 工程和两个本地 Swift Package：

- `HDiary.xcodeproj`：App、Widget Extension、UI Tests 等 Xcode targets。
- `HSharedCode`：共享基础、媒体、定位、UI 组件等模块。
- `HDiaryLibrary`：日记模型、搜索、IAP、App/Widget feature 等模块。

当前配置状态：

- Xcode 配置在 `HDiary/Configs/base.xcconfig` 中使用 `SWIFT_VERSION = 5.0`。
- `HSharedCode/Package.swift` 与 `HDiaryLibrary/Package.swift` 使用 `swift-tools-version: 5.9`。
- 尚未集中配置 strict concurrency 或 Swift 6.2+ default actor isolation。

本次目标是在当前分支升级 Swift 语言/工具版本，开启完整 Swift concurrency 检查，并按模块性质决定是否启用 Default Main Actor。

## 目标

1. SwiftPM manifest 尽量跟随本机 Swift 6.3，升级到 `swift-tools-version: 6.3`。
2. Xcode targets 使用 Swift 6 语言模式：`SWIFT_VERSION = 6.0`。
3. 开启完整 strict concurrency，让 Swift 6 并发诊断暴露真实边界问题。
4. Default Main Actor 按 target/module 需要开启或关闭：
   - UI、App lifecycle、Widget、UIKit/SwiftUI 组件默认 MainActor。
   - 模型、搜索、基础工具、媒体、IAP、Localization 等非 UI 模块保持默认 nonisolated。
5. 只修复由新并发设置直接暴露的编译错误，不做无关重构。

## 非目标

- 不升级第三方依赖版本，除非 SwiftPM resolution 因 Swift 6.3 明确要求。
- 不重写现有架构或迁移业务 API。
- 不把所有模块统一标记为 MainActor。
- 不使用 `@unchecked Sendable` 作为迁移捷径，除非某个类型已有可验证的内部同步并且没有更安全方案。

## 方案

采用分层配置：

1. **SwiftPM tools version**
   - `HSharedCode/Package.swift` 升级到 `// swift-tools-version: 6.3`。
   - `HDiaryLibrary/Package.swift` 升级到 `// swift-tools-version: 6.3`。

2. **SwiftPM strict concurrency**
   - 所有 package targets 使用 Swift 6 并发检查设置。
   - 优先通过共享 helper 定义 Swift settings，避免重复且方便以后调整。

3. **SwiftPM Default Main Actor**
   - 开启 MainActor 的 targets：
     - `HSharedCode`: `HUIComponent`, `HLocation`
     - `HDiaryLibrary`: `HDiaryAppFeature`, `HDiaryWidgetFeature`
   - 不开启 MainActor 的 targets：
     - `HSharedCode`: `HLocalization`, `HFoundation`, `HMedia`
     - `HDiaryLibrary`: `HDiaryModel`, `HDiarySearch`, `HDiaryConstants`, `HDiaryIAP`
     - 所有 test targets 默认不启用 MainActor，除非编译错误表明测试本身必须跟随 UI isolation。

4. **Xcode build settings**
   - `HDiary/Configs/base.xcconfig` 将 `SWIFT_VERSION` 升到 `6.0`。
   - 在共享配置中开启完整 strict concurrency。
   - 在 App/Widget 对应 xcconfig 中开启 Default Main Actor。
   - 不在 UI tests 或项目级配置里无差别开启 Default Main Actor。

## 迁移错误处理

构建或测试中如果出现 Swift 6 strict concurrency 诊断，按以下优先级修复：

1. 对 UI/lifecycle 代码，优先保持或补足 MainActor 边界。
2. 对纯数据/value 类型，必要时补充安全的 `Sendable`。
3. 对共享可变状态，优先改为 actor、MainActor、锁保护类型或消除共享状态。
4. 对 async 调用边界，显式添加 `await`、调整 isolation，或把调用移动到正确 actor。
5. 避免用 `Task {}`、`nonisolated(unsafe)`、`@unchecked Sendable` 掩盖诊断。

## 验证

实施后需要验证：

1. Swift Package 解析和构建不因 tools version 升级失败。
2. Xcode scheme `HDiary` 能在当前 worktree 的 simulator 配置下构建。
3. 如有可用测试，运行现有 SwiftPM/Xcode 测试，确认 strict concurrency 迁移没有破坏行为。
4. 如果 XcodeBuildMCP session defaults 指向主 checkout，先按当前 worktree 的 `.xcodebuildmcp/config.yaml` 重新设置 defaults。

## 风险与缓解

- **风险：Swift 6.3 tools version 要求协作者也使用支持 Swift 6.3 的 Xcode/Swift。**
  - 缓解：这是用户选择的目标；PR 描述中明确最低工具链要求。
- **风险：strict concurrency 会暴露较多现有并发问题。**
  - 缓解：只修直接相关编译错误，并保持模块边界清晰。
- **风险：Default Main Actor 误用于非 UI 模块会隐藏并发边界。**
  - 缓解：只在 UI/App/Widget/定位打开 URL 等主线程 API 模块启用。
