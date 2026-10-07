# Issue #38：iPhone Duo 适配

验证日期：2026-10-06 至 2026-10-07。工程 `HDiary.xcodeproj`，scheme `HDiary`，Xcode 27.1。

## 截图反馈对应修复

| 现象 | 原因与处理 |
| --- | --- |
| 乐事列表加号停留顶部 | 自定义菜单带有转场修饰，不能仅依赖 `.primaryAction` 推断竖向表现；在 iOS 27.1+ 对整个 toolbar item 指定 `.axisBehavior(.verticalPreferred)`，保留菜单和缩放转场。 |
| 详情参与者行与侧栏重叠 | 原来是嵌套的横向滚动行；改为按容器可用宽度换行的 `HFlowLayout`，保留每位参与者的详情入口，无需固定侧栏宽度或设备判断。 |
| 参与者列表的添加按钮停留顶部 | 原按钮只有文字，系统按规则将其留在水平栏；统一使用同时提供本地化标题和 plus 图标的 `Label`，让系统选择合适的工具栏表现。 |
| 参与者编辑页的确认按钮停留顶部 | 保留 `.confirmationAction`，统一为按钮提供文字和 checkmark 图标，使其支持右侧竖栏；保存逻辑不变。 |
| Duo 竖屏侧栏布局中，顶部标题随滚动收起的行为不同 | 原来各页使用 `.automatic`，其行为受 `.searchable` 配置影响。现在在 `toolbarVerticalEdge` 非空时统一使用 `.toolbarMinimizationBehavior(.onScrollDown, for: .navigationBar)`，顶部标题随上滑收起、下滑恢复，右侧按钮保持固定；普通水平导航栏仍使用系统默认策略。内容必须足够长、可以滚动才能观察这一行为。 |

依据：[Apple Duo 工具栏讲解](https://developer.apple.com/videos/play/tech-talks/111462/)、[axisBehavior](https://developer.apple.com/documentation/swiftui/toolbarcontent/axisbehavior(_:))、[默认导航栏收起行为](https://developer.apple.com/documentation/swiftui/toolbarminimizationbehavior/automatic)。

## 保留范围与撤回项

2026-10-06 按必要性逐项收窄后，源码从 19 个文件、215 行新增/93 行删除，缩减为 10 个文件、61 行新增/17 行删除。2026-10-07 补充上述参与者确认按钮，并按反馈移除 Label 的版本分支：所有系统均提供文字和图标，仅新系统 API 保留 availability 检查。

除上述修复外，仅保留：

- 编辑器取消、确认按钮统一使用带图标的 `Label`，确认按钮使用 `.confirmationAction`，支持 Duo 竖向工具栏的系统呈现；不改保存逻辑。
- 隐私、条款页面只忽略上下安全区，保留 Duo 侧边栏需要的横向安全区。

已撤回缺少必要 Duo 适配依据的改动：详情 `GeometryReader`、图片高度公式和 820pt 正文宽度；图片填充改为适应；列表标题行数、缩略图裁切；编辑器多行标题、正文高度、日期标签、键盘按钮、参与者换行和固定缩略图尺寸；评分样式、触控和辅助功能改造；没有业务调用的 `ZoomImageView` 修改；相关本地化与临时测试标识。

## 配置与源码审计

- 工程与 `app.xcconfig` 已开启自动 launch screen 和 scene manifest；iPad 声明四个方向，iPhone 声明竖屏及左右横屏；未发现 `UIRequiresFullScreen`。本次未改这些配置。
- 应用使用 SwiftUI `App` / `WindowGroup` 生命周期；`UIApplicationDelegateAdaptor` 只负责初始化通知服务，没有窗口或布局管理需要迁移。
- 未发现 `UIScreen.main`、按 interface orientation 布局或对称安全区假设。日记建议的 `userInterfaceIdiom` 检查是既有能力可用性判断，图片裁剪器的黑色全屏背景是预期行为，保留。

## 构建与静态检查

沿用原有的数据编辑和保存方式；独立草稿、保存失败恢复及对应测试已按要求移除。收窄后的源码已于 2026-10-06 22:41 CST 通过原生 Xcode `BuildProject`（18.313 秒，0 错误），使用共享配置的 `HDiary` scheme 与 `hdiary 17pro` 目标。22:14 的构建只对应收窄前版本。

2026-10-07 的参与者确认按钮及旧系统兼容修改已于 10:08 CST 通过原生 Xcode `BuildProject`（8.233 秒，0 错误）。此前远端应用构建与测试已在 Xcode 27.1 通过；截图 CI 的六个参与者场景因“添加”文字变成 plus 图标失败，当时增加了 iOS 26.5 的文字分支。该中间版本的本地 `AllParticipantsSnapshotTests` 的全部六个参数场景于 10:12 CST 通过，未修改截图基准或比较容差。这份结果不覆盖随后统一 Label 的最终修改；双设备新版基准与比较结果另行记录。

随后同步主分支的 XcodeGen 迁移，沿用其 Xcode 27.1 CI 配置，工程重复生成与目标、scheme、测试计划、依赖锁验证通过。

`git diff --check` 通过。本机 SwiftLint 为 0.63.3，仓库配置锁定 0.58.0；用只去掉版本锁的临时配置检查剩余 10 个源码文件，发现的 7 项违规与 HEAD 基线逐项一致，无新增违规。不能将其称为仓库原配置严格 lint 通过。

## 双设备截图基准（2026-10-07）

现有 26 个截图场景分别保留普通 iPhone 和 iPhone Duo 两份，共 52 张，旧无设备后缀基准已替换。范围为乐事列表、标签列表／详情、参与者列表／详情，包含空态、深色、大字号和原有窄宽度场景。

| 设备 | 系统 | 基准尺寸 | 文件后缀 |
| --- | --- | --- | --- |
| iPhone 17 Pro | iOS 27.0 (24A94232) | 402 × 874 pt，3x | `-iphone.png` |
| iPhone Duo，Closed 竖屏 | iOS 27.1 (24A94401) | 466 × 678 pt，3x | `-iphone-duo.png` |

两者均使用 Xcode 27.1。当前安装的 iOS 27.1 runtime 只支持 Duo，因此普通 iPhone 使用 iOS 27.0；原有 `compact-accessibility` 场景继续限制为 320 pt 宽。CI 对这两个目标分别新建模拟器、运行同一 `HDiarySnapshots` 计划并保存独立 artifact，关闭基准录制。

测试从专用宿主自己的窗口读取 scene 尺寸、安全区和显示比例，并检查设备型号、系统版本及竖屏尺寸。新建 Duo 默认 Closed 竖屏，生成图确认真实右侧导航栏和 Tab 栏；没有以普通手机的固定安全区伪造 Duo。

录制和比较过程中发现 Duo Tab 选中背景可能处于过渡形状，故仅在截图宿主关闭 UIKit 动画。另一次失败的 reference/actual PNG 全图最大仅相差 2 级 RGB，差异位于玻璃阴影；比较前使用 SnapshotTesting 自身的 PNG 编解码统一内存图像与磁盘基准的表示。仍沿用 `precision: 1, perceptualPrecision: 0.94`，未放宽容差。

最终本地比较结果：

- Duo：完整 `HDiarySnapshots` 计划通过，日志 `test_sim_2026-10-07T02-43-56-722Z_pid78656_b80e66dc.log`；26 个截图场景及计划内的数据／头像测试均通过。
- 普通 iPhone：完整 `HDiarySnapshots` 计划通过，日志 `test_sim_2026-10-07T02-45-27-741Z_pid78656_807b9659.log`；26 个截图场景及计划内的数据／头像测试均通过。

所有基准已逐组查看；截图证明静态布局，不代替点击、滚动及形态切换验收。CI 矩阵通过 YAML 和 Bash 语法检查，工程稳定生成检查通过。

## 实际交互证据

所有测试启动均使用 DEBUG 内存样本容器及临时启动参数，未清空用户的持久化数据。

| 设备 | 系统 | 模拟器 UUID | 记录 |
| --- | --- | --- | --- |
| iPhone Duo | iOS 27.1 (24A94401) | `20FBB94C-16B2-459A-A4FA-7EC0BED06B4E` | 收窄前已安装并启动 22:14 构建；Closed 竖屏[乐事加号进入右侧栏](duo-closed-list-plus.jpg)。其余交互验证受设备控制工具阻塞，详见[运行记录](duo-runtime.md)。 |
| hdiary 17pro | iOS 26.5 | `A044BA15-7770-48E6-8E28-E2123A772ACD` | 前轮[启动及列表观察](iphone-17pro-ios26.5-notes.md)，主要流程回归尚未完成 |
| iPad Pro 13 (M5) | iOS 26.5 | `2D15C1CC-968A-4A02-B13A-20166E188204` | [运行记录](ipad-runtime.md) |

以下运行证据来自收窄前版本。其覆盖安装、启动、Duo 竖屏乐事加号位置及部分列表布局观察；乐事加号的实现此次没有改变。修复前已实际复现[详情参与者被右侧栏遮挡](duo-before-detail-participant-overlap.png)。形态切换中的导航、编辑器、键盘、大字号及图片操作仍缺少完整的实际交互证据；构建和静态检查不能替代这些验收。

最新产物验证期间，Device Hub 没有提供应用内部的可访问性元素，坐标点击也未产生可观察的页面变化；设备前台随后切换到其他模拟器。按工具重试上限停止尝试。因此参与者添加入口、详情参与者换行、顶部标题上滑收起/下滑恢复和右侧按钮固定仍未完成实际交互验收，不能仅凭源码或列表截图标记通过。

2026-10-07 最终统一 Label 后尝试在共享 `hdiary 17pro` 上补充交互验证，native 设备选择不接受该 iOS 26.5 目标（UUID 和名称各试一次均失败），因此未获得新增点击证据。没有操作用户数据；Xcode 和第三方 MCP 已恢复共享默认上下文。
