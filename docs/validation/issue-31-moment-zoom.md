# Issue #31：乐事详情缩放转场

## 实现

- iOS App 与 HDiaryAppFeature 的最低版本均为 iOS 26；原生 Zoom Navigation Transition 从 iOS 18 起可用，因此没有提高最低系统版本。
- `MomentNavigationLink` 在实际卡片标签上注册 `matchedTransitionSource`，使用持久的 `moment.uuid`，而非行号或标题。
- 每个链接持有独立的 `Namespace`。同一乐事同时出现在搜索、分组列表或关联列表时，不会共享动画来源。跨分组移动导致原链接消失时，不会匹配到另一张卡片。
- 统一的 `moment` 路由通过可选 `zoomSource` 携带点击时的 UUID 和 namespace；参数默认值为 `nil`，保留普通入口的调用方式。减弱动态效果开启时，链接选择普通路由。转场选择在进入前确定，不在详情编辑中切换视图结构。
- 标签页中的圆角材质卡片将背景和内边距包含在动画来源内。
- 缩放、返回手势及来源消失后的收尾交由系统处理；未添加自定义手势、动画时长或模型副本。详情页及其编辑 sheet 沿用原实现。
- 本次不涉及新建乐事转场（#29）或新增删除功能。原有只读媒体管理入口沿用普通详情路由。

参考：[Apple ZoomNavigationTransition](https://developer.apple.com/documentation/swiftui/zoomnavigationtransition)。

## 2026-10-02 验证记录

环境：`HDiary.xcodeproj` / `HDiary`，模拟器 `hdiary 17pro`，UUID `A044BA15-7770-48E6-8E28-E2123A772ACD`。

- 最终源码已通过 XcodeBuildMCP `build_run_sim` 并安装启动。构建日志：`~/Library/Developer/XcodeBuildMCP/workspaces/HHappyDocs-13f4eabc96d9/logs/build_run_sim_2026-10-02T05-32-13-678Z_pid36458_1929fa31.log`。警告来自未修改的 CloudData / ExportData 文件。
- 首轮实际点击两个不同标题的无封面乐事，详情内容对应正确；返回按钮可以回到原列表，再打开另一条乐事；编辑 sheet 可打开并取消。
- 首轮录屏 `/tmp/hdiary-issue31-zoom.mp4` 的抽帧确认系统缩放展开；此次操作没有修改或删除现有乐事。
- 改动文件 `git diff --check` 通过。
- SwiftFormat 原配置检查存在全文件的历史缩进不一致；对比 HEAD 确认其他已修改文件原来同样存在。仅禁用 `indent` 规则后，本次 9 个 Swift 文件检查通过。未对整文件重新格式化。
- SwiftLint 本机为 0.63.3，仓库要求 0.58.0，原配置运行因版本不一致退出，不能记为通过。

## 待完成的运行验收

以下项目没有足够证据，不能勾选完成：

- 交互式返回及中途取消后再次编辑、再次返回。
- 有封面卡片的动画衔接和无闪烁。
- 编辑日期导致跨组/排序变化、来源删除或不可见时的系统回退。
- 无来源入口、减弱动态效果的实际运行验证。

工具限制：初次 Xcode 原生桥接打开工程超时，随后使用 XcodeBuildMCP 构建和操作。连续手势尝试后自动化点击无可见效果；重新构建启动后，在尚未进入详情的列表页也出现同样现象。因此不能判定它是缩放转场取消缺陷，也不能宣称手势验收通过。改用 Xcode `DeviceInteractionStartSession` 时返回“等待用户批准”，需在菜单栏 Xcode MCP 中批准 `Verify Moment Zoom` 请求后继续验证。

## 2026-10-03 路由合并复核

按评审意见将两个详情路由合并为 `moment(Moment, editEnabled: Bool, zoomSource: MomentZoomSource? = nil)`。普通入口保持原调用形式，卡片按减弱动态效果设置传入可选来源。合并后 `HDiary` 模拟器构建通过；`git diff --check` 及两处路由文件禁用历史 `indent` 规则的 SwiftFormat 检查通过。本轮未重复运行交互验收，上述待验收项仍保留。
