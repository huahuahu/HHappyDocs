# Issue #43：联系人头像预览

## 实现与取舍

- 可见圆形头像直接作为 SwiftUI `Button` 的 label，保留 `.plain` 样式、圆形点击区域和“查看头像”无障碍标签。加载中、占位图、禁用预览以及替换图片尚未加载完成时，只有展示视图。
- `ParticipantAvatarPreview.previewURL` 绑定系统 `.quickLookPreview`。文件准备由视图作用域的 `.task` 驱动；准备中和已呈现时拒绝重复请求；联系人、原图或预览开关变化时重置状态，忽略旧请求晚到的结果。
- `ParticipantAvatarPreviewFiles` actor 在主线程之外识别图片类型并原样写入数据。预览不使用头像缩略图，也不重新编码。写入失败显示中英文错误说明和重试按钮，不呈现空 URL。
- 系统 modifier 没有公开的关闭动画/分享完成回调，因此不在 URL 变成 nil 或头像视图消失时删除文件。成功准备的文件位于 `tmp/ParticipantAvatarPreviews/<session UUID>/<preview UUID>/image.<原扩展名>`，本进程内持续可用，下次进程首次准备预览时清理之前会话的目录。该策略优先保证系统预览、关闭动画与分享读取期间的文件有效性；本次进程中反复打开的文件会保留到下一会话清理。
- 预览文件名固定为 `image`，保留原始类型扩展名；每次准备使用独立子目录，避免同名原图互相覆盖或被 Quick Look 复用旧内容。
- 只清理该组件专属根目录中以 UUID 命名的旧会话；取消写入或写入失败时立即清理该次文件。系统也可按临时目录规则回收文件。
- 删除无人调用的 `AvatarImageView.supportPreview` 分支及 `HPreviewButton`/`HPreviewItem` 桥接；头像编辑/选择的现有显示布局保持原样。

API 依据：[Apple quickLookPreview(_:)](https://developer.apple.com/documentation/swiftui/view/quicklookpreview(_:))，2026-10-07 通过本地 Sosumi MCP 读取。绑定非 nil 时呈现，用户关闭后系统复位为 nil。

## 可复现验收入口

Xcode app target 中 `HDiary/Preview Content/AvatarPreviewValidation.swift` 的“头像预览 · 交互与失败重试”Preview 使用独立内存联系人，不连接业务数据库。测试控件包含原图替换、联系人切换、缺失/无效/透明图片、禁用预览、可手动放行的图片加载、一次真实文件系统写入失败，以及打开预览时刷新父视图。

运行时验收临时将 app 根视图替换为该验证页，验收后恢复 `HDiary/HDiaryApp.swift`；正式 app 入口不包含测试路由。旧桥接对照仅存在于临时验收构建中，不保留在提交源码中。

## 验证环境与结果

- 仓库配置保留 `HDiary` / `hdiary 17pro`（A044BA15-7770-48E6-8E28-E2123A772ACD，iOS 26.5）。旧版基线构建、安装与启动成功；原生设备交互接口拒绝26.5，XcodeBuildMCP 与底层 AXe 均只返回空 Application 根节点，因此该设备的头像交互无法验证。
- 补充交互环境：HDiary Snapshot iPhone 17 Pro（040ECFE5-4ED3-4795-AC27-23490CF57596，iOS 27.0），与配置设备同机型。
- 聚焦单元测试通过：XcodeBuildMCP `test_sim`，scheme `HDiary`，配置指定的 iOS 26.5；`ParticipantAvatarPreviewTests`、`ParticipantAvatarImageTests`、`ParticipantAvatarLoaderTests` 共20项测试，0失败。新用例覆盖原始PNG/JPEG字节与完整尺寸、重复点击、关闭重开、取消、晚到结果、真实写入失败后的重试，以及文件跨关闭/重置保留、下一会话清理和临时目录被系统回收后重建。
- 文件名改为 `image` 后，在正式 App 入口下重新运行 `ParticipantAvatarPreviewTests`，8项测试通过、0失败。PNG/JPEG用例检查可见文件名与真实扩展名；连续准备不同原图的用例确认两个 URL 独立，旧图内容不会被新图覆盖。[本轮结果](filename-tests-summary.json)。
- 既有整页截图通过：`HDiarySnapshotHost`，iPhone17Pro / iOS27.0；`AllParticipantsSnapshotTests` 的6个场景、`ParticipantDetailSnapshotTests` 的5个场景全部通过，没有修改基准图或容差。
- 本次头像源码及新增测试/Preview通过严格SwiftLint。共享 `DiaryStringKey.swift` 原有10项诊断在HEAD基线与修改后相同，没有新增诊断。机器SwiftLint为0.63.3，仓库配置标注0.58.0；使用只更新版本标注的临时配置运行同一组规则，未更改仓库配置。
- 原生Xcode `BuildProject` 即使选择指定模拟器仍错误使用macOS SDK，因此编译/测试回退到XcodeBuildMCP；没有为该工具行为修改业务代码或工程平台设置。
- 恢复正式 App 入口、移除临时旧桥接对照并重新生成工程后，`HDiary` / 指定 iOS 26.5 的最终构建通过（`CODE_SIGNING_ALLOWED=NO`）。构建仍报告既有文件中的并发、SwiftData 导入和弃用 API 警告，没有编译错误。
- 最终11个头像源码、测试与 Preview 文件通过严格 SwiftLint，`git diff --check` 通过；正式源码已无 `HPreviewButton` / `HPreviewItem` 引用。

## 设备交互验收

2026-10-07，在同一 iPhone 17 Pro / iOS 27.0 模拟器、同一内存验证页对照新旧实现：

下表截图和转场录像采集于文件名改为 `image` 之前，其中显示的 UUID 属于当时的文件名。这些材料保留作为交互和转场证据。

| 场景 | 结果与证据 |
| --- | --- |
| 打开、关闭、重开、连续点击 | 有效头像打开完整原图；连续点击3次仅出现一个 Quick Look 界面，关闭后可重开。[原图](preview-original.png) |
| 原图质量与缩放 | 新旧均显示完整 A 图，双击后图像区域由402×301.5放大到2000×1500。[缩放](preview-zoomed.png)；PNG/JPEG原始字节和完整尺寸另由单元测试核对。 |
| 更换原图与联系人 | 更换 B 后缩略图与预览均为 B。[新原图](preview-latest-original.png)。另在两个联系人分别持有“加载完成”图、B图时切换，头像随当前联系人更新，打开后确认完整 B 原图。[切换后状态](switched-distinct.png)，完整打开过程见转场录像。 |
| 无头像、无效及全透明图片 | 均保留姓名首字占位，移除新实现的预览按钮。[透明占位](transparent-placeholder.png)、[层级](transparent-placeholder-accessibility.txt)，以及[无头像](removed.txt)、[无效图片](invalid.txt)。 |
| 禁用与加载中 | 禁用时没有预览按钮；暂停替换图加载时仍显示旧 A 图，但没有预览按钮，放行后显示“加载完成”图并恢复按钮。[禁用](disabled.txt)、[加载中](paused-loading.txt)、[完成](loading-completed.txt)。 |
| 真实写入失败与重试 | 让普通文件占据目标目录，实际触发文件系统错误；显示中文提示，没有空白预览，点击“重试”后正常打开。[错误提示](write-failure-alert.png)、[重试成功](retry-success.png)。 |
| 预览期间父视图刷新 | 预览打开时刷新计数从1变2，只有一个预览；关闭后计数为2且入口正常。[结果层级](refresh-count-after-preview.txt)。 |
| 分享 | 新旧都打开系统分享面板，显示 PNG Image · 19 KB。[新实现](preview-share.png)、[旧实现](legacy-share.png)。未向外部应用发送图片。 |
| 按钮语义与邻近点击 | 新头像在无障碍层级中是64×64的“查看头像”Button；邻接“刷新”只增加计数，同行联系人文字、行中空白不打开预览。[按钮层级](avatar-accessibility.txt)。 |

首次分享尝试没有显示分享面板，日志出现 ShareSheet 文件获取警告；检查时目标PNG仍完整可读（800×600，19,331 bytes）。关闭重开后分享成功，旧实现也成功，后续没有复现。保留此观察，不将首次异常误记为已稳定重现的业务缺陷。

源代码为按钮 label 设置 `contentShape(Circle())`。在圆的外接矩形近角处点击仍观察到一次系统命中，原因未进一步确定；本轮已确认同行文字、明确空白和相邻按钮不会被头像捕获。

实际 VoiceOver 朗读与焦点顺序、真机，以及正式联系人列表到详情的完整导航没有在本轮单独验证。无障碍结论限于工具返回的按钮语义与标签；列表本身继续以默认 `supportsPreview: false` 使用头像，页面布局由既有截图测试覆盖。

文件名改为 `image` 后的补充验收已构建并打开 Quick Look，但首帧仍处于加载态，随后原生设备交互工具返回 `Session not found`，本轮未取得加载完成后的标题和分享面板截图。文件名及文件内容隔离已通过上述8项预览测试；不将旧截图或加载态画面作为更名后的界面验证证据。

## 转场取舍

30 fps录像逐帧核对确认，两个实现的转场不同：

- 新 `.quickLookPreview` 使用系统纵向模态呈现，并向下关闭；录像46.10–46.60秒为打开，104.20–104.70秒为关闭。
- 旧桥接从头像位置缩放展开、关闭时缩回；117.45–117.95秒为打开，166.40–166.90秒为关闭。

本次保留原生 modifier。工单优先采用 SwiftUI 状态呈现，缩放、关闭和分享均已在对照中通过；接受来源转场由系统接管，不再提供旧桥接的头像缩放动画。若后续明确要求保持头像来源缩放，可另行评估由 `.sheet(item:)` 驱动的独立控制器桥接；本次没有增加此层。

[转场对照关键帧](transition-contact-sheet.jpg) · [原始录像](new-old-transition.mp4)

验收结束后，录像已停止、设备交互 session 已关闭；XcodeBuildMCP 默认项目、scheme与模拟器仍与仓库配置一致。临时 App 入口和旧实现对照源码均已恢复/删除，正式入口的最终构建结果见 [build-summary.json](build-summary.json)。
