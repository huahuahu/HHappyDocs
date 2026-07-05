# Swift Package 壳层架构设计

## 背景

当前仓库已经扁平化为单一 HDiary 项目：根目录保留 `HDiary.xcodeproj`、`HDiary/` app target、`HDiaryWidget/` widget target、测试目录，以及两个 Swift Package：`HDiaryLibrary` 和 `HSharedCode`。`HDiaryLibrary` 已经包含 `HDiaryConstants`、`HDiaryModel`、`HDiarySearch`、`HDiaryIAP` 等业务模块，`HSharedCode` 提供跨 app 的 Foundation、媒体、定位、本地化和通用 SwiftUI 组件。

长期目标是让 `HDiary.xcodeproj` 只承担平台壳层和 Xcode 集成职责，把可测试逻辑、可复用 UI、feature UI 和 widget 共享逻辑逐步迁入 Swift Package。

## 目标

1. 将 `HDiary.xcodeproj` 收敛为 app/widget 壳和平台集成点。
2. 继续扩展现有 `HDiaryLibrary`，通过新增 package targets 承载 HDiary 专属 service、feature UI 和共享 UI。
3. 保持依赖方向单向：app/widget 依赖 package，package 不反向依赖 app target。
4. 每个迁移阶段都只改变代码归属，不改变 SwiftData schema、CloudKit、app group、bundle id、存储路径或用户数据语义。
5. 每次迁移都可独立构建和测试，避免一次性大重构。

## 非目标

1. 不移除 `.xcodeproj`，因为 capabilities、entitlements、embedded extension、scheme、target graph 和 package product wiring 仍由 Xcode project 表达。
2. 不新建 `HDiaryFeatures` package，也不把 HDiary 代码拆成多个 package；当前阶段优先在 `HDiaryLibrary` 内新增 targets。
3. 不迁移或重写 SwiftData schema、CloudKit identifier、app group 或持久化路径。
4. 不把 widget 的 WidgetKit entry、timeline provider 壳层和 extension 专属配置迁入 package。
5. 不引入 XcodeGen、Tuist 或其他 project generator。

## 架构边界

`HDiary.xcodeproj` 保留以下职责：

1. `@main` app 入口、AppDelegate 和平台生命周期 glue code。
2. Root scene、root view composition、tab/root feature 组装和环境注入。
3. Capabilities、entitlements、Info.plist、asset catalog、StoreKit 配置、scheme、test plan、widget embedding。
4. App target、widget target、test targets 与 Swift Package products 的 wiring。

`HDiaryLibrary` 承担以下职责：

1. HDiary 业务模型、领域规则、搜索、IAP、启动维护、通知/URL 处理中的可测试逻辑。
2. 不依赖 app target 的 SwiftData service 和数据维护 service。
3. 可复用 SwiftUI 组件，以及边界稳定后的 feature UI。
4. App 和 widget 共享的展示模型、formatting、timeline 辅助逻辑和业务计算。

`HSharedCode` 继续只承载跨 app 通用能力。只有在组件确实不包含 HDiary 领域语义时，才放入 `HSharedCode`。

## Package target 结构

保留现有 targets：

1. `HDiaryConstants`
2. `HDiaryModel`
3. `HDiarySearch`
4. `HDiaryIAP`

新增 targets 按层和 feature 拆分：

1. `HDiaryServices`：启动数据维护、通知调度、存储统计、CloudData 查询等非 UI service。
2. `HDiaryUI`：HDiary 专属但跨 feature 复用的 SwiftUI 组件、样式、formatter 和 view helpers。
3. `HDiarySearchFeature`：Search 页面、推荐、状态展示和搜索入口 view。
4. `HDiaryLibraryFeature`：Library、tag、participant、chart、entry 等页面入口。
5. `HDiarySettingsFeature`：Settings、debug、storage、cloud data、help/about 等页面入口。
6. `HDiaryMomentsFeature`：Moment list、detail、edit、suggestion、filter 等页面入口。
7. `HDiaryWidgetSupport`：app/widget 共用的 widget 展示模型、时间线辅助逻辑和小组件格式化逻辑。

Feature target 只暴露少量 public 入口，例如 feature root view、coordinator 或 factory。Feature 之间不直接互相 import；需要共享的内容先提升到 `HDiaryUI`、`HDiaryServices`、`HDiaryModel` 或 `HSharedCode`。

## 依赖方向

推荐依赖方向：

```text
HDiary app / HDiaryWidget
  -> HDiary feature targets
    -> HDiaryUI / HDiaryServices
      -> HDiarySearch / HDiaryIAP / HDiaryModel / HDiaryConstants
        -> HSharedCode targets
```

约束：

1. Package targets 不 import `HDiary` app target，也不依赖 app target 中的 global environment。
2. Widget 只依赖适合 extension 使用的 package products；不把 app-only API 暴露给 widget。
3. SwiftData model 和 container 语义保持在 `HDiaryModel` 及现有 container 边界内，迁移 service 时只改变调用位置和文件归属。
4. Resources 和 localization 跟随所属 target 明确声明，避免依赖 app bundle 的隐式查找。

## 迁移顺序

### 第一期：非 UI 逻辑和 root 副作用

先从低风险、可测试、依赖少的代码开始：

1. 从 root view 和 app target 中抽出启动数据维护、legacy media migration、media info 更新、deleted moment cleanup 等 service。
2. 抽出搜索 glue、通知调度、URL handling 中不依赖 UIKit/SwiftUI 生命周期的部分。
3. 将 service 暴露为 package API，由 app 壳在启动或 root composition 中调用。

### 第二期：共享 UI 和小组件

迁移不依赖 app root environment 的 UI：

1. HDiary 专属样式、empty/error/progress view、通用 cell、formatter 等进入 `HDiaryUI`。
2. 当前已经足够通用的组件继续放在 `HSharedCode/HUIComponent`。
3. Preview 使用 package 可访问的 sample data 或 dependency injection，不读取 app target 私有状态。

### 第三期：Feature UI

按 feature target 分阶段迁移：

1. 先迁 `Search`，因为已有 `HDiarySearch` 作为底层模块，边界相对清晰。
2. 再迁 `Library` 和 `Settings`，把 feature root view 作为 public API 暴露给 app 壳。
3. 最后迁 `Moments`，因为它涉及 list/detail/edit、navigation、SwiftData 写入和媒体编辑，依赖最多。
4. App target 最终只负责 import feature products 并在 root composition 中组装。

### 第四期：Widget 共享逻辑

Widget target 保留 WidgetKit entry、bundle、timeline provider 壳和 extension 配置。可共享的展示模型、formatting、时间线辅助逻辑进入 `HDiaryWidgetSupport`，同时保持 app group、CloudKit identifier 和存储路径不变。

## 错误处理

Package service 不吞错误，也不新增无日志的 early return。可恢复错误使用 `throws`、显式结果类型或现有日志风格返回给 app/widget 壳层。App/widget 壳负责决定日志、用户提示、重试或降级行为。

现有 SwiftData container 初始化失败策略不在本设计中改变。如果要改善启动失败体验，需要单独设计，因为它会影响 app 生命周期和用户可见行为。

## 验证策略

每个阶段使用现有工具验证：

1. Swift Package targets：运行现有 SwiftPM build/test。
2. App 和 widget：使用现有 `HDiary` scheme 通过 XcodeBuildMCP 构建/测试。
3. 配置一致性：检查 Debug/Release bundle id、Info.plist、entitlements、deployment target、signing、app group 和 CloudKit 配置保持不变。
4. 依赖方向：确认 package targets 没有反向依赖 app target，feature targets 之间没有形成横向耦合。
5. 资源和 localization：确认迁移后的 package resources 能从对应 bundle 正确加载。

## 成功标准

1. `HDiary.xcodeproj` 的职责收敛为 target graph、platform integration 和 root composition。
2. `HDiary/` app target 中的 Swift 文件数量持续下降，核心业务逻辑和 feature UI 逐步迁入 `HDiaryLibrary` targets。
3. App 和 widget 行为保持一致，不改变用户数据、CloudKit、app group 或存储路径。
4. 新增 package targets 边界清晰，feature 入口可独立理解、测试和替换。
5. 每个迁移阶段都有可重复的构建或测试验证。
