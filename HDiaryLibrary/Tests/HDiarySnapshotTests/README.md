# 列表 Snapshot 单元测试

`MomentListSnapshotTests` 和 `AllTagsSnapshotTests` 直接创建实际 SwiftUI 列表、与 App 共用的 `HDiaryTabShell` 外层结构和独立的 SwiftData 内存数据，用 `assertSnapshot(of:as:)` 的 SwiftUI 接口渲染并比较图片。通过专用的空白 `HDiarySnapshotHost` 提供渲染窗口，不启动业务 App，无 XCUIApplication 或点击操作。

| 场景 | 检查目的 |
| --- | --- |
| Moment · grouped | 搜索栏、三个 Tab 的图标与标题、7 条日记的日期分组与数量；已删除记录不出现 |
| Moment · expanded | 展开内容、长标题截断、标签、本地缩略图、纯文字行 |
| Moment · empty | 原有空列表的导航标题、Tab 栏与空白布局；与实际 App 一致，空数据时没有搜索栏 |
| Tag · empty | 中文空态、返回和添加按钮；排序按钮及总数隐藏 |
| Tag · populated | 默认名称排序、0/1/多条关联乐事、行间距、底部总数与工具栏 |
| Tag · long-names | 长中文、英文和 emoji 标签的换行、行高与导航箭头布局 |
| Tag · dark | 普通列表的深色背景、主次文字、导航栏与 Tab 栏 |
| Tag · accessibility | accessibility2 字号下的长名称、乐事数量、行高及遮挡情况 |

标签数据和五个 Preview 共用 `Sources/HDiaryAppFeature/Library/Tags/TagList/Preview/`，通过真实 `Tag` / `Moment` 关系生成数量。每个场景均有独立的内存容器，不使用共享 Preview 容器或导航单例。

Moment 数据与三个 Preview 共用 `Sources/HDiaryAppFeature/Moments/MomentList/Preview/MomentListPreviewFixture.swift`。固定时间为 2026-10-03 12:00 UTC+8，固定公历、浅色、默认字号，图片无需网络或相册。每个场景使用独立内存容器，CloudKit 关闭。`ListSnapshotFixtures` 在首次渲染前同时准备 Moment 和 Tag 的所有场景，并保留容器到进程结束，避免已卸载 Tab 页面的 SwiftData 查询收到后续建库的保存通知而崩溃。

在 Xcode 中运行：

1. 打开 `HDiary.xcodeproj`，选择 `HDiary` scheme。
2. 选择项目配置的 `hdiary 17pro` 模拟器（iOS 26.5）。
3. 在模拟器设置 → 辅助功能 → 显示与文字大小中开启“非颜色区分”（与基准环境保持一致）。
4. 在 Product → Test Plan 中选择 `HDiarySnapshots`，按 Command-U 运行。

基准分别位于 `__Snapshots__/MomentListSnapshotTests/` 和 `__Snapshots__/AllTagsSnapshotTests/`，每张图片的说明由上表和测试名称维护，无需在图片上添加文字。普通比较不会自动更新基准。

审核设计变化后，只选中需要更新的测试，在 `HDiarySnapshots` 测试计划的配置环境变量中临时设置 `HDIARY_RECORD_SNAPSHOTS=1`，运行测试录制基准。录制时报告失败是 SnapshotTesting 提醒审核图片的正常行为。检查新图片后，删除或禁用该环境变量，再按 Command-U 验证比较通过。

本地反复运行 XcodeBuildMCP 的 `.xctestproducts` 时，曾观察到安装包已经更新、测试进程却仍执行旧代码的情况。如果输出包含已删除的诊断文字，或失败行号与当前源码不符，先在配置的模拟器中卸载专用 `HDiarySnapshotHost`（bundle ID：`com.tiger.suzhou.HDiarySnapshotHost`），再重新构建并运行测试。该 host 只服务截图测试。CI 每次新建模拟器，不复用本地 host。

独立测试计划 `HDiarySnapshots` 使用项目指定的 iPhone 17 Pro / iOS 26.5，固定渲染尺寸 402 × 874 pt、3x（基准图 1206 × 2622 px）。测试以独立的 Xcode 单元测试 target 运行，其 Resources 直接引用 App 的 `HDiary/Localizable.xcstrings`，不复制或另外维护翻译。测试计划固定简体中文及中国地区，页面标题、日期分组和日记内容均为中文；测试同时断言导航标题的中文资源已加载。host 也引用同一字符串目录，并在初始化时固定自己的语言偏好为简体中文，保证共享库提前解析的 Tab 文案使用中文。布局使用 `.image(layout: .device(config: config), traits: traits)` 保留固定尺寸、safe area 和 3x 显示比例；简单组件也可使用 `.fixed(width:height:)`。SnapshotTesting 内部通过 UIHostingController 将 SwiftUI View 放进测试 host 的窗口，使用 `drawHierarchyInKeyWindow: true` 捕获导航栏和 Tab 栏的系统合成外观。玻璃阴影可能产生 1–2 RGB 级别的微小波动，沿用现有 `precision: 1, perceptualPrecision: 0.94`：检查所有像素，容许轻微感知色差。系统效果仍依赖固定的 Xcode、runtime 和设备配置。升级 Xcode 或 iOS runtime 需单独审核基准。

数据验证放在 `HDiaryAppFeatureTests` 的 `MomentListFixtureTests` 和 `AllTagsFixtureTests`，`HDiarySnapshots` 只选择这两个 suite 及原有 `AllTagsViewTests`。它们在独立于截图 host 的测试 runner 中建库和删除数据，避免测试顺序影响渲染，同时在同一 CI 工作流验证数据和图片。标签测试还会通过新建 ModelContext 验证已保存的关联数量。

测试计划的 `selectedTests` 使用 Xcode 生成的对象格式：Swift Testing 用例写在 `suites`，XCTest 用例写在 `xctestClasses`。不要改成旧的字符串数组格式，否则 Swift Testing 用例会被当成 XCTest 筛选条件，运行时被遗漏。

外层结构直接复用 App 的 TabView、Tab 标签和搜索修饰器。Moment 快照固定选中“乐事”，Tag 快照固定选中“资料库”。Tag 使用独立 NavigationStack 及实际 `.libraryEntry(entry: .tag)` destination，保留真实页面的中文内联标题与返回按钮。未选中的 Tab 使用空内容，不运行其业务逻辑。本测试覆盖列表页面与外层结构，不覆盖搜索、排序菜单点击、增删、详情跳转、Tab 切换或系统状态栏。

GitHub Actions 的 `iOS snapshots` 工作流在 push、pull request 和手动运行时执行同一 `HDiarySnapshots` 测试计划。CI 使用 `xcode-27` runner，固定与本地相同的 Xcode 27.1 Beta（27A9269）、iPhone 17 Pro / iOS 26.5，关闭并行测试和基准录制。依赖版本来自提交的 `Package.resolved`。工作流检查 Xcode build 号，并下载、缓存和导入固定的 iOS 26.5 runtime。关闭失败时的 sysdiagnose 收集，保留 XCTest 图片附件，避免模拟器诊断超时拖慢运行。CI 同时固定“非颜色区分”为开启；它会改变 DisclosureGroup 箭头样式，需要与本地基准一致。不要为了让 CI 变绿而自动录制或覆盖基准。

运行结束后，在 Actions 的 `list-snapshots` artifact 中下载 `xcodebuild.log`、可由 Xcode 打开的 `Lists.xcresult`，以及截图附件。图片不匹配时包含 reference、actual 和 difference 附件，便于审核是否为预期的界面变化。报告保留 14 天。

2026-10-04 本地验证：上述固定环境下，完整 `HDiarySnapshots` 计划的 8 个截图场景及 5 个数据／状态用例全部通过（参数化标签测试在结果摘要中计为一个方法，总计 9 个测试方法）。仅将 fixture 中的“旅行”临时改为“旅行（变化验证）”时，普通和深色两个场景均报告图片不匹配，其余三个场景通过；恢复数据后完整计划通过。五张标签基准已人工检查，原有三张乐事基准未更新。远程 CI 尚未运行。
