# Widget 单元截图测试

`HDiaryWidgetSnapshots` 是 XCTest **单元测试** scheme，使用项目已有的 SnapshotTesting 1.19.6。在测试进程中直接构造正式 `MomentWidgetContentView`，交给库内部的 `UIHostingController` 渲染，再与 PNG 基准逐像素比较。没有 `XCUIApplication`、桌面点击、专用测试 Widget、App Group、Timeline reload 或刷新等待。

这是常见的组件视觉回归做法：[Point-Free SnapshotTesting](https://github.com/pointfreeco/swift-snapshot-testing) 支持直接测试 SwiftUI View，并指定尺寸和 traits。业务逻辑继续由普通单元测试覆盖；系统集成效果使用 Preview／人工验收。

## 正式 UI 与测试的关系

`MomentWidgetEntryView` 在真实 WidgetKit 环境读取只读的 `widgetFamily`，传给 `MomentWidgetContentView`。内容 View 将 family 传给列表和行，因此测试可以直接选择 Medium／Large，不需要修改系统环境或复制正式布局。`widgetRenderingMode` 是可写环境值，测试注入 `.fullColor`／`.accented` 来覆盖 Header 的图标选择分支。

样例和 Preview 共用 `MomentWidgetPreviewFixtures`，固定日期、UUID、姓名、正文和头像；测试固定中文 locale、公历、UTC+8 和 3× 像素比例。保留当前生产代码的日期格式。资源仍来自正式 App 的 asset catalog 和 `Intents.xcstrings`。

复用已有 `HDiarySnapshotHost` 作为 **hosted unit test** 的容器；它提供窗口、中文环境和 `Bundle.main` 资源，也供列表单元截图使用。Host App 的存在不意味着 UI 自动化。宿主不再嵌入 fixture Widget，也不需要 App Group entitlement。

## 覆盖与边界

| 覆盖 | Medium | Large |
| --- | --- | --- |
| fullColor／accented × 浅色／深色 × 符号头像／彩色头像 | 8 | 8 |
| 长姓名和正文、单条、空数据、所有参与者、AX1 整卡 | 5 | 5 |
| AX5 的单行降级组件（按内容高度截图） | 1 | 1 |
| 合计 | 14 | 14 |

共 28 张基准，由 `testMedium`、`testLarge`、`testAccessibility5Rows` 三个测试方法执行。整卡画布是固定的 350×164 pt／350×365 pt，内边距 16 pt；这是组件回归约束，不能当作所有设备的系统 Widget 尺寸。背景是普通浅色／深色画布，不伪造系统圆角、壁纸或玻璃材质。

**accented 截图不是最终 Tinted／Glass 截图。** 它验证应用自己的条件分支，例如选择 `WidgetAppIconAccented`；它不能验证系统最终的染色、图片去色、accent 分组、透明背景和 Liquid Glass 合成。[Apple HIG](https://developer.apple.com/design/human-interface-guidelines/widgets#Appearances) 说明这些效果由系统应用。最终效果需通过正式 Widget 的 Xcode Preview 外观选择及主屏检查。

普通 `UIHostingController` 与 WidgetKit 的字体表现也不同。本次直接注入 AX5 时，中号整卡发生裁切，不能将它当作之前系统 AX5 截图的等价结果。因此整卡明确覆盖 AX1，AX5 单独测试行组件，不宣称完成主屏 AX5 整卡验收。生产字体和布局没有为了通过这个迁移而调整。

不覆盖 Provider／AppIntent 查询、时间线调度、业务数据到主屏更新、点击跳转或所有配置的笛卡尔积。

## 运行与基准维护

基准固定在 **iPhone 17 Pro、iOS 27.0（24A434）**。不用修改主屏、墙纸和图标设置。推荐继续使用 `HDiary Snapshot iPhone 17 Pro`，也可用相同型号／runtime 的其他模拟器。

1. 执行 `./scripts/generate-project.sh`，打开 `HDiary.xcodeproj`。
2. 选择 `HDiaryWidgetSnapshots` scheme、Debug 和上述模拟器。
3. 运行 `MomentWidgetSnapshotTests`。

命令行也可运行：

```bash
HDIARY_DESTINATION='platform=iOS Simulator,name=HDiary Snapshot iPhone 17 Pro' \
  ./scripts/test-ios-project.sh HDiaryWidgetSnapshots \
  -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO
```

默认 `record: .never`；缺少基准也会失败，不自动生成或覆盖。明确接受视觉变更后，向 test runner 传入 `HDIARY_RECORD_WIDGET_SNAPSHOTS=1`，或在命令行设置 `TEST_RUNNER_HDIARY_RECORD_WIDGET_SNAPSHOTS=1`。录制会报告失败以提醒检查；审核图像后关闭录制再比较。

基准位于 `Tests/__Snapshots__/MomentWidgetSnapshotTests/`，使用 `moment-widget-content` 前缀，与旧系统截图不同。比较采用 `precision: 1`、`perceptualPrecision: 1`。失败时 reference、actual 和 difference 图片会保存在 `.xcresult`；不自动重试、不自动放宽容差。

CI 在 `iOS snapshots` 的 iPhone job 中运行此 scheme，显式禁用录制，并上传 `Widgets.xcresult` 与失败附件。Duo 没有这组基准。远端执行状态以实际 Actions run 为准。

## 本次验证

2026-10-11：按用户要求，从当前源码重新构建并录制单元截图基准。Widget 的 28 张图片与上一轮单元截图基准完全一致；关闭录制后，**28 张比较通过，3 个测试方法通过，0 失败／跳过**。方法执行合计 0.757 秒，含启动的工具总耗时 9.191 秒。此次测试构建无 warning／error；迁移时的正式 App 和 Widget Debug 构建成功记录仍保留在结果文件中。

Review：[中号总览](../docs/validation/issue-37/widget-unit-snapshots/medium.png)、[大号总览](../docs/validation/issue-37/widget-unit-snapshots/large.png)、[结果与产物路径](../docs/validation/issue-37/widget-unit-snapshots/results.json)。历史主屏截图证据保留在 `docs/validation/issue-37/widget-snapshots`，不作为当前单元测试通过的证据。

共用宿主的列表三项按整组重新录制后，关闭录制连续两次 **3／3 通过**。最终仅 `moment-list.empty-iphone.png` 的文件内容变化，玻璃区域相差最多 2 级 RGB 值；展开和分组列表的最终基准与本轮之前一致。此次未修改测试源码或比较容差。

原先的 `testExpandedList` 差异，以及本轮单独录制后再运行整组时出现的差异，保留在 [基准刷新记录](../docs/validation/issue-37/widget-unit-snapshots/baseline-refresh.json)。差异根因尚未确认；列表本来就是单元截图测试，不能归因于 Widget 从 UI 自动化迁移。旧 [差分区域](../docs/validation/issue-37/widget-unit-snapshots/list-smoke-difference.png) 是刷新前的历史证据。本轮未运行其他 snapshot 用例、其他设备或远端 CI。
