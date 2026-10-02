# Issue #29：新建乐事缩放转场

## 实现

- 项目最低系统版本已统一提升至 iOS 26，将工具栏中持续存在的新建控件作为 `matchedTransitionSource`，整个新建 sheet 使用 `navigationTransition(.zoom(...))`。空白记录与日记建议共用该来源，菜单项本身不参与匹配。
- 将记录方式与转场选择放在同一个 sheet item 中，避免首次呈现读取到另一个 State 的旧值。每次打开时采样“减弱动态效果”，编辑期间不切换视图分支，以保留草稿身份。
- 开启“减弱动态效果”时走原有 sheet；缩放配置仅属于列表入口，独立使用 `AddMomentNavigationView` 不会强制匹配列表来源。目前没有直接新建的深链接路由。
- 访问权限尚未解析时用 `ProgressView` 提供实际呈现根视图。实际验证曾观察到 `EmptyView` 初始根节点导致空白 sheet；修改后初始化和编辑器显示正常。
- 保留原来的保存、取消、日记建议转换与照片选择流程，不新增自动键盘焦点或定时延迟。

## 2026-10-01 验证

环境：Xcode 27.1 beta、HDiary scheme、仓库配置的 hdiary 17pro（iOS 26.5，A044BA15-7770-48E6-8E28-E2123A772ACD）。

| 检查 | 结果 |
| --- | --- |
| 首次打开从右上角入口缩放展开 | 最终构建录屏逐帧确认 |
| 点击取消缩回入口 | 最终构建录屏逐帧确认 |
| 再次打开 | 编辑器正常显示，标题为空 |
| 标题输入、键盘、保存 | 实际输入并保存，今天的记录数从 0 增至 1 |
| 取消和下拉交互式关闭 | 返回列表，今天的记录数保持 1 |
| 打开照片选择器 | 截图确认系统照片网格正常呈现；未完成选图返回流程，工具的 AX 快照只返回底层应用 |
| 日记建议菜单 | 模拟器没有显示该菜单，需支持 JournalingSuggestions 的真机验证 |
| 减弱动态效果 | 已实现回退分支，尚未完成运行时验证 |
| 深链接直接新建 | 当前不存在该路由，未新增 |

保存/输入和下拉关闭在合并 sheet 参数之前的中间构建完成；最终构建复核了首次缩放、取消、再次打开与照片选择器呈现。

早期验证的标准构建被已有 `HDiaryWidgetIntents/MomentWidget/MomentWidgetIntent.swift` 的三个 AppIntents 本地化错误阻止（要求 LocalizedStringResource 使用 main bundle）。通过 XcodeBuildMCP 对验证构建传入 `LM_SKIP_METADATA_EXTRACTION=YES` 后构建运行成功；该覆盖没有写入项目配置，也不代表 AppIntents 或发布构建通过。现有并发等编译警告未在本任务扩展处理。

录屏保存在本机 Codex artifacts：`/Users/tigerguo/.codex/visualizations/2026/10/01/01a0f6eb-8986-7231-b310-4f5c75c56201/issue29/zoom-open-close.mp4`。

Apple API 依据：[navigationTransition(_:)](https://developer.apple.com/documentation/swiftui/view/navigationtransition(_:)) 明确支持 sheet，最低 iOS 18。

最低版本提升后的复核：App/Widget 共用配置、HDiaryLibrary 与 HSharedCode 均设为 iOS 26；移除本次转场的 iOS 18 可用性判断。使用相同临时元数据跳过参数构建运行成功，生成的 App Info.plist 中 MinimumOSVersion 为 26.0。

## AppIntents 构建错误修复

同日后续已修复 `MomentWidgetIntent` 的元数据提取错误：省略 `LocalizedStringResource` 的显式 `bundle: .main` 参数，使用其默认主 bundle。当前 Xcode 27.1 beta 对显式参数报错，默认参数则正常导出；本地化 key、Intents 表和翻译均保持原样。

- 不传入 `LM_SKIP_METADATA_EXTRACTION` 的正常构建、安装、启动通过。
- 构建日志确认 App、Widget 扩展及 Intents 包执行了 `ExtractAppIntentsMetadata`。
- App 和 Widget 扩展均生成 `Metadata.appintents/extract.actionsdata`，包含 MomentWidgetIntent 和三个本地化 key。
- 两个宿主 bundle 的 `en.lproj/Intents.strings` 与 `zh-Hans.lproj/Intents.strings` 均包含正确的标题、描述、参数名称和“所有人”翻译。
- 此项验证覆盖构建与产物内容，未复核系统 Widget 配置页的实际显示。
