# 整页 Snapshot 单元测试

`MomentListSnapshotTests`、`AllTagsSnapshotTests`、`TagDetailSnapshotTests`、`AllParticipantsSnapshotTests` 和 `ParticipantDetailSnapshotTests` 直接创建实际 SwiftUI 页面、与 App 共用的 `HDiaryTabShell` 外层结构和独立的 SwiftData 内存数据，用 `assertSnapshot(of:as:)` 的 SwiftUI 接口渲染并比较图片。通过专用的空白 `HDiarySnapshotHost` 提供渲染窗口，不启动业务 App，无 XCUIApplication 或点击操作。

`HDiarySnapshotTests` 是普通的 Xcode Unit Testing target；“Snapshot”只描述图片断言方式。SnapshotTesting 可以用于 Swift Package 的 `.testTarget`，简单组件的截图也不需要专门的宿主 App。但当前 SwiftPM 的测试 target 没有指定自定义 Host Application 的配置项。这里要捕获导航栏和 Tab 栏的系统玻璃效果，使用 `drawHierarchyInKeyWindow: true`，因此通过 Xcode 单元测试 target 的 `TEST_HOST` 配置现有的空白 `HDiarySnapshotHost`。测试直接导入 `HDiaryAppFeature` 等 Package 产品。

测试源码、独立计划 `HDiarySnapshots.xctestplan` 和二十六张基准保存在仓库根目录的 `HDiarySnapshotTests/`，宿主保存在 `HDiarySnapshotHost/`。XcodeGen 根据 `project.yml` 生成与实际目录对应的分组；添加或移除文件后重新生成工程。Package 的 `Tests/` 只保留 Package 自己的测试。测试计划、`README.md` 和 `__Snapshots__/` 不加入测试 bundle；SnapshotTesting 根据测试源码路径读取基准。App 的 `HDiary/Localizable.xcstrings` 通过 target membership 同时提供给宿主和测试，不复制翻译文件。

相关说明：[SnapshotTesting 的 SwiftPM 用法](https://github.com/pointfreeco/swift-snapshot-testing/blob/1.19.6/README.md#swift-package-manager)、[维护者关于系统玻璃效果和宿主的说明](https://github.com/pointfreeco/swift-snapshot-testing/issues/1029#issuecomment-3366942138)。

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
| Tag detail · populated | “城市”标题与备注、10 条关联乐事、日期倒序、不同星级、中英西文标题、编辑与返回按钮、Tab 栏 |
| Tag detail · empty | 当前标签没有乐事时的中文空态；其他标签的乐事不混入 |
| Tag detail · long-content | 长导航标题、多行备注、长乐事标题的截断与卡片布局 |
| Tag detail · dark | 详情页深色背景、卡片材质、评分、主次文字和系统栏 |
| Tag detail · accessibility | accessibility2 字号下评分、日期上下排列，避免日期被挤成竖列 |
| Tag detail · accessibility-max | accessibility5 最大字号下的评分、完整日期与自然换行 |
| Tag detail · compact-accessibility | 320 pt 窄宽度、accessibility2 字号下的卡片和日期布局 |
| Participant · populated | 真实参与者列表的导航栏、添加按钮、总人数、头像网格和资料库 Tab |
| Participant · empty | 中文空态、返回及添加按钮、底部 Tab 栏 |
| Participant · dark | 深色列表背景、图片原色、头像首字、系统导航栏和 Tab 栏 |
| Participant · accessibility | accessibility3 字号下长中文、英文昵称换行与自适应网格 |
| Participant · avatar-variants | 整页检查彩色图片、透明／缺失／损坏头像回退、emoji、空昵称和空姓名 |
| Participant · single-participant | 只有一个参与者时的网格宽度、总人数与留白 |
| Participant detail · populated | 图片头像、昵称和姓名、备注、3 条关联乐事、返回／编辑／删除按钮和 Tab 栏 |
| Participant detail · empty | 无头像、备注和关联乐事时的真实详情布局；其他人的乐事不混入 |
| Participant detail · dark | 完整详情页的深色样式，头像与列表保持同源 |
| Participant detail · accessibility | accessibility3 字号下头像缩放、姓名、备注、乐事标题和系统栏 |
| Participant detail · transparent-avatar | “宝宝”的透明头像显示“宝”，完整详情保留备注和关联乐事 |

参与者的列表与详情测试分别渲染 `AllParticipantsPreview` 和 `ParticipantDetailPreview`。两者通过正式 `HDiaryDestination` 路由使用 App 的 `AllParticipantsView` / `ParticipantDetailView`，共用生产 `HDiaryTabShell`；测试不重新拼装页面，也没有单独的头像展示板。App target 的 Canvas Preview 使用相同宿主与数据。详情通过真实 `Participant` / `Moment` 关系显示备注和关联乐事。关联乐事按日期倒序显示，与标签详情一致，避免 SwiftData 无序关系导致页面顺序漂移。

所有参与者场景均在 `ListSnapshotFixtures` 中提前建立并保存独立内存容器，与其他页面一起保留到进程结束。截图前等待真实 `ParticipantAvatarImageStore` 完成解码，不使用固定延迟或替代图片；统一按最大受测字号和 3x 比例预热，避免测试顺序改变缓存分辨率。头像无闪烁的状态切换继续由 `ParticipantAvatarLoaderTests` 验证；整页截图验证最终呈现，不验证点击头像后 Quick Look 的交互。

标签数据和五个 Preview 共用 `HDiaryLibrary/Sources/HDiaryAppFeature/Library/Tags/TagList/Preview/`，通过真实 `Tag` / `Moment` 关系生成数量。每个场景均有独立的内存容器，不使用共享 Preview 容器或导航单例。

标签详情数据和七个 Preview 共用 `HDiaryLibrary/Sources/HDiaryAppFeature/Library/Tags/TagDetail/Preview/`。普通场景使用固定的“城市”标签、备注和 10 条虚构乐事，按日期从旧到新插入，由实际页面按日期倒序显示。另有一条属于其他标签的乐事，用来验证数量和空态只取当前标签的关系。时间、评分和文本均固定，不读取用户数据。

详情截图宿主共用 App 的 `Assets.xcassets` 和 `AccentColor`，使用实际资源中的橙色而不额外覆盖页面 tint，保留系统工具栏按钮的默认外观。参与者页面同样使用 App 的 AccentColor；现有 Moment / Tag 截图仍沿用各自的显式 tint。

`MomentItemView` 的评分使用随 Dynamic Type 缩放的 caption 字体，布局占位与显示尺寸一致。评分和日期通过 `ViewThatFits(in: .horizontal)` 优先并排显示；完整日期放不下时改为上下排列，日期可利用整行宽度自然换行。辅助功能、最大字号与窄宽度基准覆盖这一回归。

Moment 数据与三个 Preview 共用 `HDiaryLibrary/Sources/HDiaryAppFeature/Moments/MomentList/Preview/MomentListPreviewFixture.swift`。固定时间为 2026-10-03 12:00 UTC+8，固定公历、浅色、默认字号，图片无需网络或相册。每个场景使用独立内存容器，CloudKit 关闭。`ListSnapshotFixtures` 在首次渲染前同时准备 Moment、Tag、Tag detail、Participant 和 Participant detail 的所有场景，并保留容器到进程结束，避免已卸载 Tab 页面的 SwiftData 查询收到后续建库的保存通知而崩溃。

在 Xcode 中运行：

1. 按[根目录说明](../README.md)安装固定的 XcodeGen 2.46.0，运行 `./scripts/generate-project.sh`，再打开 `HDiary.xcodeproj`，选择 `HDiarySnapshotHost` scheme。
2. 选择项目配置的 `hdiary 17pro` 模拟器（iOS 26.5）。
3. 使用系统默认的辅助功能设置；如果本地曾开启“非颜色区分”，在模拟器设置 → 辅助功能 → 显示与文字大小中将它恢复为默认关闭，与 CI 新建模拟器保持一致。
4. 使用该 scheme 默认的 `HDiarySnapshots` 测试计划，按 Command-U 运行截图及相关数据／状态测试。只运行截图时，在 Test Navigator 中运行 `HDiarySnapshotTests`。主 App 的 `HDiary` scheme 继续使用原有通用计划，不包含截图 target。

测试范围统一在 `HDiarySnapshots.xctestplan` 中管理：包含整个 `HDiarySnapshotTests` target，以及 `HDiaryAppFeatureTests` 中的 `MomentListFixtureTests`、`AllTagsFixtureTests`、`TagDetailFixtureTests`、`AllTagsViewTests`、`ParticipantAvatarImageTests` 和 `ParticipantAvatarLoaderTests` 六组测试。选择的是整组测试，组内新增用例会自动纳入。两个 target 均关闭并行执行，测试语言和地区固定为简体中文／中国。

基准分别位于 `__Snapshots__/MomentListSnapshotTests/`、`__Snapshots__/AllTagsSnapshotTests/`、`__Snapshots__/TagDetailSnapshotTests/`、`__Snapshots__/AllParticipantsSnapshotTests/` 和 `__Snapshots__/ParticipantDetailSnapshotTests/`，每张图片的说明由上表和测试名称维护，无需在图片上添加文字。普通比较不会自动更新基准。

审核设计变化后，只选中需要更新的测试，在 `HDiarySnapshots` 测试计划的配置环境变量中临时设置 `HDIARY_RECORD_SNAPSHOTS=1`，运行测试录制基准。录制时报告失败是 SnapshotTesting 提醒审核图片的正常行为。检查新图片后，删除或禁用该环境变量，再按 Command-U 验证比较通过。

本地反复运行 XcodeBuildMCP 的 `.xctestproducts` 时，曾观察到安装包已经更新、测试进程却仍执行旧代码的情况。如果输出包含已删除的诊断文字，或失败行号与当前源码不符，先在配置的模拟器中卸载专用 `HDiarySnapshotHost`（bundle ID：`com.tiger.suzhou.HDiarySnapshotHost`），再重新构建并运行测试。该 host 只服务截图测试。CI 每次新建模拟器，不复用本地 host。

截图使用项目指定的 iPhone 17 Pro / iOS 26.5，默认渲染尺寸 402 × 874 pt、3x（基准图 1206 × 2622 px）；`compact-accessibility` 使用 320 × 874 pt（960 × 2622 px），在同一 runtime 中验证窄宽度布局。测试以独立的 Xcode 单元测试 target 运行，其 Resources 直接引用 App 的 `HDiary/Localizable.xcstrings`，不复制或另外维护翻译。宿主在初始化时固定自己的语言为简体中文、地区为中国，Preview 固定 locale 和时区；无需修改其他测试的语言设置。系统文案和日期使用中文；标签详情同时保留中英西文的虚构乐事标题以检查混排。测试会断言导航标题的中文资源已加载。host 也使用同一字符串目录，保证共享库提前解析的 Tab 文案使用中文。布局使用 `.image(layout: .device(config: config), traits: traits)` 保留固定尺寸、safe area 和 3x 显示比例；简单组件也可使用 `.fixed(width:height:)`。SnapshotTesting 内部通过 UIHostingController 将 SwiftUI View 放进测试 host 的窗口，使用 `drawHierarchyInKeyWindow: true` 捕获导航栏和 Tab 栏的系统合成外观。玻璃阴影可能产生 1–2 RGB 级别的微小波动，沿用现有 `precision: 1, perceptualPrecision: 0.94`：检查所有像素，容许轻微感知色差。系统效果仍依赖固定的 Xcode、runtime 和设备配置。升级 Xcode 或 iOS runtime 需单独审核基准。

数据验证放在 `HDiaryAppFeatureTests` 的 `MomentListFixtureTests`、`AllTagsFixtureTests` 和 `TagDetailFixtureTests`；独立计划选择这三个 suite、原有 `AllTagsViewTests` 及两个头像解码／加载 suite，连同 `HDiarySnapshotTests` 一起运行。它们在独立于截图 host 的测试 runner 中建库和删除数据，避免测试顺序影响渲染，同时在同一 CI 工作流验证数据和图片。标签测试还会通过新建 ModelContext 验证已保存的关联数量，详情数据测试同时检查日期、评分和不相关乐事的隔离。

外层结构直接复用 App 的 TabView、Tab 标签和搜索修饰器。Moment 快照固定选中“乐事”，Tag、Participant 及各自详情快照固定选中“资料库”。Tag 使用独立 NavigationStack 及实际 `.libraryEntry(entry: .tag)` destination；Tag detail 以实际标签列表 destination 为父页面，预先推入 `.tag(tag:)` destination。由于预填路径跳过了父页面的导航栏过渡，详情 Preview 显式使用正常导航后继承的内联标题模式，返回和编辑按钮仍由真实页面提供。未选中的 Tab 使用空内容，不运行其业务逻辑。参与者列表使用实际 `.libraryEntry(entry: .participant)` destination；参与者详情以该列表为父页面，预先推入 `.participant` destination，提供独立的 `NavigationStore`。本测试覆盖列表、标签详情、参与者详情页面与外层结构，不覆盖搜索、排序菜单点击、编辑操作、增删、导航交互、Tab 切换或系统状态栏。

GitHub Actions 的 `iOS snapshots` 工作流在 push、pull request 和手动运行时，使用 `-scheme HDiarySnapshotHost -testPlan HDiarySnapshots` 运行独立计划，命令不再维护 `-only-testing` 清单。CI 使用 `xcode-27` runner，固定 Xcode 27.1、iPhone 17 Pro / iOS 26.5，关闭并行测试和基准录制。依赖版本来自根目录提交的 `Package.resolved`；CI 先安装固定版本 XcodeGen 并生成工程，生成 hook 将锁文件恢复到工程 workspace 后，再通过 `-onlyUsePackageVersionsFromResolvedFile` 解析依赖。工作流检查 Xcode 公开版本，记录实际 build 号并用于依赖缓存隔离，同时下载、缓存和导入固定的 iOS 26.5 runtime。关闭失败时的 sysdiagnose 收集，保留 XCTest 图片附件，避免模拟器诊断超时拖慢运行。CI 使用新建模拟器的默认辅助功能设置，不写入系统 Accessibility 偏好；基准使用默认关闭的“非颜色区分”。不要为了让 CI 变绿而自动录制或覆盖基准。

运行结束后，在 Actions 的 `list-snapshots` artifact 中下载 `xcodebuild.log`、可由 Xcode 打开的 `Lists.xcresult`，以及截图附件。图片不匹配时包含 reference、actual 和 difference 附件，便于审核是否为预期的界面变化。报告保留 14 天。
