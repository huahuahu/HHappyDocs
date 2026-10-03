# 列表 Snapshot 单元测试

`MomentListSnapshotTests` 直接创建实际 SwiftUI 列表、与 App 共用的 `HDiaryTabShell` 外层结构和独立的 SwiftData 内存数据，用 `assertSnapshot(of:as:)` 的 SwiftUI 接口渲染并比较图片。通过专用的空白 `HDiarySnapshotHost` 提供渲染窗口，不启动业务 App，无 XCUIApplication 或点击操作。

| 场景 | 检查目的 |
| --- | --- |
| grouped | 搜索栏、三个 Tab 的图标与标题、7 条日记的日期分组与数量；已删除记录不出现 |
| expanded | 展开内容、长标题截断、标签、本地缩略图、纯文字行 |
| empty | 原有空列表的导航标题、Tab 栏与空白布局；与实际 App 一致，空数据时没有搜索栏 |

数据与三个 Preview 共用 `Sources/HDiaryAppFeature/Moments/MomentList/Preview/MomentListPreviewFixture.swift`。固定时间为 2026-10-03 12:00 UTC+8，固定公历、浅色、默认字号，图片无需网络或相册。每个场景使用独立内存容器，CloudKit 关闭。测试在首次渲染前准备所有场景，并保留容器到进程结束，避免已卸载 Tab 页面的 SwiftData 查询收到后续建库的保存通知而崩溃。

在 Xcode 中运行：

1. 打开 `HDiary.xcodeproj`，选择 `HDiary` scheme。
2. 选择项目配置的 `hdiary 17pro` 模拟器（iOS 26.5）。
3. 在 Product → Test Plan 中选择 `HDiarySnapshots`，按 Command-U 运行。

基准位于 `__Snapshots__/MomentListSnapshotTests/`，每张图片的说明由上表和测试名称维护，无需在图片上添加文字。普通比较不会自动更新基准。

审核设计变化后，在 `HDiarySnapshots` 测试计划的配置环境变量中临时设置 `HDIARY_RECORD_SNAPSHOTS=1`，运行测试录制基准。录制时报告失败是 SnapshotTesting 提醒审核图片的正常行为。检查新图片后，删除或禁用该环境变量，再按 Command-U 验证比较通过。

独立测试计划 `HDiarySnapshots` 使用项目指定的 iPhone 17 Pro / iOS 26.5，固定渲染尺寸 402 × 874 pt、3x（基准图 1206 × 2622 px）。测试以独立的 Xcode 单元测试 target 运行，其 Resources 直接引用 App 的 `HDiary/Localizable.xcstrings`，不复制或另外维护翻译。测试计划固定简体中文及中国地区，页面标题、日期分组和日记内容均为中文；测试同时断言导航标题的中文资源已加载。host 也引用同一字符串目录，并在初始化时固定自己的语言偏好为简体中文，保证共享库提前解析的 Tab 文案使用中文。布局使用 `.image(layout: .device(config: config), traits: traits)` 保留固定尺寸、safe area 和 3x 显示比例；简单组件也可使用 `.fixed(width:height:)`。SnapshotTesting 内部通过 UIHostingController 将 SwiftUI View 放进测试 host 的窗口，使用 `drawHierarchyInKeyWindow: true` 捕获导航栏和 Tab 栏的系统合成外观。重复运行时，系统玻璃阴影约 0.42% 的像素有 1–2 RGB 级别的微小波动，因此使用 `precision: 1, perceptualPrecision: 0.99`：检查所有像素，容许很小的感知色差，避免阴影噪声导致失败。系统效果仍依赖固定的 Xcode、runtime 和设备配置。升级 Xcode 或 iOS runtime 需单独审核基准。

验证环境：Xcode 27.1 Beta，iOS 26.5。三张基准已人工查看；普通比较及数据隔离共 4 个用例通过，受控修改基准后已确认出现图片差异失败。

外层结构直接复用 App 的 TabView、Tab 标签和搜索修饰器。快照固定选中“乐事”；未选中的资料库和设置页使用空内容，不运行其业务逻辑。本测试覆盖列表页面与外层结构，不覆盖搜索交互、Tab 切换或系统状态栏。

GitHub Actions 的 `iOS snapshots` 工作流在 push、pull request 和手动运行时执行同一 `HDiarySnapshots` 测试计划。CI 固定 macOS 26 runner、Xcode 26.5、iPhone 17 Pro / iOS 26.5，关闭并行测试和基准录制。依赖版本来自提交的 `Package.resolved`。本地当前使用 Xcode 27.1 Beta，CI 工具链首次比较需要单独验证；不要为了让 CI 变绿而自动录制或覆盖基准。

运行结束后，在 Actions 的 `moment-list-snapshots` artifact 中下载 `xcodebuild.log`、可由 Xcode 打开的 `MomentList.xcresult`，以及截图附件。图片不匹配时包含 reference、actual 和 difference 附件，便于审核是否为预期的界面变化。报告保留 14 天。
