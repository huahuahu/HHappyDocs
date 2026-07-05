# 纯文本配置与 Swift Package 迁移设计

## 背景

项目目前保留一个 `HDiary.xcodeproj`，同时已有 `HDiary/Configs/base.xcconfig`、`debug.xcconfig`、`release.xcconfig`，以及两个 Swift Package：`HSharedCode` 和 `HDiaryLibrary`。`HDiaryLibrary` 已经承载 `HDiaryModel`、`HDiaryConstants`、`HDiaryIAP`，SwiftData `@Model` 和 `ModelContainer` 也已经在 package 内。`HDiary` app target 仍包含大量 SwiftUI feature、启动编排、搜索、数据维护和平台 glue code。

目标是让项目尽可能使用纯文本维护：把可文本化的 Xcode build settings 移到 xcconfig，把可复用和可测试的代码逻辑逐步移到 Swift Package，并且每一步都保持 app 可构建。

## 目标

1. 保留现有 `.xcodeproj`，但把它收敛为薄壳：主要负责 targets、schemes、capabilities、entitlements、resources、Package 依赖和 Xcode 必需元数据。
2. 将重复或稳定的 build settings 移到分层 xcconfig，让版本、bundle id、deployment target、Swift version、签名、Info.plist、entitlements 等配置可以用纯文本 review。
3. 将 app target 中的业务逻辑、数据服务、搜索和可复用 SwiftUI 组件逐步迁入 Swift Package。
4. 每个迁移阶段都可以独立构建和验证，避免一次性大重构。

## 非目标

1. 不引入 XcodeGen、Tuist 或其他项目生成工具。
2. 不把 `.xcodeproj` 完全变成生成物。
3. 不在本次迁移中顺手修改 SwiftData schema、CloudKit 行为或持久化数据结构。
4. 不强行迁移 target membership、build phases、Package product dependency、scheme 等 Xcode 原生结构。

## 总体架构

`HDiary.xcodeproj` 继续存在，但定位为 app 壳层和集成点。`HDiary` app target 最终主要保留：

- `@main` app 入口
- AppDelegate 和平台生命周期 glue code
- root composition，例如 root scene、tab 组装和环境注入
- app 专属资源入口、entitlements、Info.plist
- 与 Xcode capability、extension embedding、asset catalog 相关的集成配置

Package 层按依赖方向组织：

```text
HDiary app / HDiaryWidget
  -> feature/domain package targets
    -> HDiaryLibrary targets
      -> HSharedCode targets
```

Package 不能反向依赖 app target。Widget 与 app 共享的逻辑优先放入 `HDiaryLibrary` 或新增 package target；WidgetKit 生命周期、timeline provider 入口和 extension 专属配置仍留在 widget target。

## xcconfig 设计

采用 include 链分层，而不是把所有设置塞入单个文件。每个 Xcode build configuration 仍只引用一个 xcconfig，这个入口文件再通过 `#include` 组合共享配置。

建议层次：

1. `base.xcconfig`：所有 target 共享的基础值，例如 `MARKETING_VERSION`、`CURRENT_PROJECT_VERSION`、`IPHONEOS_DEPLOYMENT_TARGET`、`SWIFT_VERSION`、`DEVELOPMENT_TEAM` 和通用 asset catalog 设置。
2. `debug.xcconfig` / `release.xcconfig`：只放配置维度差异，例如 Debug bundle suffix、Release 签名/优化相关设置。
3. target-specific xcconfig：例如 app、widget、tests 的入口配置，放 `PRODUCT_BUNDLE_IDENTIFIER`、`PRODUCT_NAME`、`INFOPLIST_FILE`、`CODE_SIGN_ENTITLEMENTS`、Widget asset catalog 设置等。

不迁移的内容包括 target membership、build phases、embedded extension、Package product dependency、scheme 和 entitlements 文件本体。这些内容在 `.xcodeproj` 或 `.xcscheme` 中维护更符合 Xcode 模型。

## Swift Package 设计

现有 package 边界保持：

- `HSharedCode`：通用基础能力、通用 SwiftUI 组件、媒体、定位、本地化等跨 app 可复用代码。
- `HDiaryLibrary`：HDiary 领域模型、常量、IAP、SwiftData 容器、领域相关资源。

新增 package target 应按功能边界小步引入。优先候选：

1. 搜索相关 service/engine：当前 `HDiary/Search/Model` 使用 `ModelContainer` 和 `ModelContext`，适合先抽出为可测试的 package target。
2. 启动数据维护：`BaseTabView` 中的 legacy image migration、media info 更新、deleted moment cleanup 应从 View 中抽成 service，由 app 启动层调用。
3. 可复用 UI 组件：只迁移不依赖 app root environment、不依赖 app 专属资源的组件。
4. Feature view：在依赖梳理稳定后再逐步迁移，避免一次性把 SwiftUI navigation、environment、resource 和 preview 问题混在一起。

SwiftData `@Model` 和 container 不在本次迁移中改变语义。迁移服务逻辑时只改变代码归属，不改变 schema、relationship、CloudKit database 或存储路径。

## 迁移顺序

1. 建立基线：确认当前 app、widget 和 Swift Package 能构建/测试。
2. 迁移低风险 build settings：从重复值和纯字符串值开始，每搬一组就构建一次。
3. 接入 target-specific xcconfig：让 app、widget、tests 的 bundle id、Info.plist、entitlements 等从文本配置进入。
4. 抽出非 UI 逻辑：先迁移 utility/helper，再迁移搜索、启动数据维护等 SwiftData service。
5. 抽出可复用 UI：只迁移边界清晰、资源依赖明确的 SwiftUI 组件。
6. 评估 feature view 迁移：在基础服务和组件稳定后，再决定哪些 feature 适合进入 package。

## 错误处理

Package service 不吞错误。可恢复错误使用 `throws` 或显式结果类型返回给 app/widget 层；app/widget 层负责日志、UI 呈现或降级行为。保持现有 `Log` 使用风格，不新增无日志的 early return，也不把 `fatalError` 扩散到更多调用点。

现有 SwiftData container 初始化中的 `fatalError` 不在本设计中扩大使用范围；如需改善 container 初始化失败处理，应单独设计，因为这会影响 app 启动体验。

## 验证策略

每个阶段使用现有工具验证：

- Swift Package：运行现有 SwiftPM build/test。
- App 和 Widget：使用现有 `HDiary` scheme 通过 xcodebuildmcp 构建/测试。
- 配置迁移：检查 build settings 生效结果，确保 Debug/Release bundle id、Info.plist、entitlements、deployment target 和 signing 与迁移前一致。
- 代码迁移：确保 app target、widget target 和 tests 对 package target 的依赖方向正确，没有 package 反向依赖 app target。

## 风险与约束

1. `.xcodeproj` 不能完全消失，因为 app、widget、capabilities、embedded extension 和 scheme 仍由 Xcode 原生结构表达。
2. Swift Package 中的资源、本地化、preview 和 SwiftUI environment 需要逐步迁移，不能简单移动文件。
3. SwiftData service 迁移要避免改变 schema 和 CloudKit 配置，否则会把模块迁移变成数据迁移。
4. Widget 与 app 共享 SwiftData container 时，必须保持 app group、CloudKit identifier 和存储路径一致。

## 成功标准

1. 主要 build settings 可以通过 xcconfig review，而不是散落在 `.pbxproj` 的 build settings 中。
2. app target 中的 Swift 文件数量逐步下降，核心业务逻辑进入 Swift Package。
3. `HDiary.xcodeproj` 的职责收敛为 target graph 和平台集成，不再承载大量手写 build setting。
4. 每个迁移阶段都有构建或测试验证，且 Debug/Release、app/widget 行为保持一致。
