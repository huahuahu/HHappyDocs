# Issue #59：小组件相对日期

2026-10-12，在 `HDiary Snapshot iPhone 17 Pro`／iOS 27.0（24A434）验证。

## 展示与刷新

- 当天使用系统 `Date.AnchoredRelativeFormatStyle`，仅允许分钟、小时，并通过 `Text(.currentDate, format:)` 持续更新。中文零分钟使用系统命名文案“此刻”，其余例如“30分钟前”“3小时前”；舍入遵循系统格式规则。
- 昨天、前天与 3～6 天前按用户日历和时区的自然日判断，系统负责本地化。
- 满 7 个自然日显示月日；与当前日期不在同一日历年时加入年份。近期日期即使跨年仍保留相对表达。
- 未来时间戳显示实际日期，时间线在该时间戳到达时切换为相对时间。
- 时间线预生成未来七个当地午夜，并在下一个午夜请求新时间线。分钟／小时更新不依赖每分钟唤醒扩展；主 App 的数据变化仍走现有 WidgetSnapshotCoordinator reload。
- 每条时间线仅保存最多 8 条可展示记录，避免在未来 entry 中重复归档全部历史。
- 动态文本以本地化的分钟／小时文案预留宽度，保留中号横排、大号竖排和现有大字号降级布局。

## 已验证

- 原生 Xcode MCP 构建正式 App、Widget 与测试目标成功。
- `HDiaryWidgetFeatureTests`：13 个测试通过，0 失败／跳过。覆盖分钟与小时格式更新、自然日边界、7 天阈值、中英与英美日期顺序、上海与洛杉矶时区、23／25 小时夏令时、跨年、中国历年界、未来记录及时间线归档数量。
- `HDiaryWidgetSnapshots`：关闭录制后，4 个测试方法、36 张组件截图逐像素比较通过，0 失败／跳过。覆盖 Medium／Large、中英文日期、浅深色、accented、长内容、空数据、AX1 整卡及 AX5 行组件。查看 [中号日期总览](medium-dates.png) 和 [大号日期总览](large-dates.png)。
- WidgetKit Preview：正式 `MomentWidget` 的中号／大号均渲染成功，动态日期路径可见，未出现日期截断。查看 [中号 Preview](widgetkit-medium.png) 和 [大号 Preview](widgetkit-large.png)。引擎实际选用了 iPhone Duo／iOS 27.1；请求 `zh-Hans` override 后日期仍显示英文，因此中文结果以显式注入 locale 的组件与逻辑测试为准。原始响应见 [previews.json](previews.json)。
- 变更的 11 个实现／测试 Swift 文件通过严格 SwiftLint 规则检查；`git diff --check` 通过。机器 SwiftLint 0.63.3 与项目声明 0.58.0 不同，因此使用临时配置仅移除版本检查，保留规则；未修改仓库配置。Package.swift 的三个既有顶层常量命名告警未纳入此次代码修改。

组件截图固定到 entry 时间，验证正式格式与布局。它们不证明主屏的实际调度时刻；未在真实主屏持续等待跨午夜／跨年。WidgetKit 的时间线执行时刻仍由系统决定。详细测试计数与本机日志／xcresult 路径见 [results.json](results.json)。

## Apple 文档依据

- [Keeping a widget up to date](https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date)
- [TimeDataSource](https://developer.apple.com/documentation/swiftui/timedatasource)
- [Text.init(_:format:)](https://developer.apple.com/documentation/swiftui/text/init(_:format:)-8sfgg)
- [Date.AnchoredRelativeFormatStyle](https://developer.apple.com/documentation/foundation/date/anchoredrelativeformatstyle)
