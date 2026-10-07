# Duo 运行时验证记录

验证时间：2026-10-06（Asia/Shanghai）

本记录对应 22:14 的收窄前构建。之后仅保留必要 Duo 适配的代码范围见 [README](README.md)；不能将本记录当作收窄后版本的完整验收。

## 环境与运行方式

- 设备：iPhone Duo Simulator，iOS 27.1，UUID `20FBB94C-16B2-459A-A4FA-7EC0BED06B4E`。
- 最终检查形态：Closed、Portrait，右侧系统状态/操作栏。
- 最终应用：22:14 构建产物 `/Users/tigerguo/Library/Developer/Xcode/DerivedData/HDiary-dqemprmzojrldyfqudhljzibrvin/Build/Products/Debug-iphonesimulator/HDiary.app`。
- 通过持久 XcodeBuildMCP 安装及启动成功，bundle `com.tiger.suzhou.HDiary-Debug`，启动 PID 18451。
- 使用 `-swiftDataContainerType 2 -bypassIPRestriction YES -appLockEnabled NO -AppleLanguages (zh-Hans) -AppleLocale zh_CN`，验证使用内存样本，没有清空真实数据容器。
- 已读取共享 `.xcodebuildmcp/config.yaml` 并通过 `session_show_defaults` 确认原配置一致；仅创建非持久 `duo-verification` 会话 profile，未改配置文件。验证结束后已恢复原 unnamed/global 活动 profile（hdiary 17pro）；未切换或终止其他设备及进程。

## 已确认的视觉结果

| 项目 | 证据与结果 |
| --- | --- |
| 修复前详情参与者遮挡 | 原构建 Closed 纵向，“自然风光徒步”的参与者单行进入右侧栏，“宇哥”被返回按钮区域遮挡。已保存 `duo-before-detail-participant-overlap.png`。 |
| 最终构建列表添加按钮位置 | Closed 纵向，列表的 plus 位于右侧状态区下方，顶部标题行没有 plus。已保存 `duo-closed-list-plus.jpg`。 |
| 设备形态控制 | 在早期构建中，通过 Device Hub 的 Book/Open/Rotate 按钮实际切到 Book 横向、Open 横向、Open 纵向并观察列表。这些仅证明设备形态控制可操作，不构成最终版本所有形态的页面验收。 |

## 未完成的交互验收

以下均不能标记通过：

- 最终列表右侧 plus 点击打开新增页。
- 最终详情参与者换行以及参与者链接点击。
- 最终参与者列表右侧 plus 打开新增 sheet。
- Closed 纵向列表/标签页上滑时顶部标题随内容滚出、反向滚动恢复，同时右侧操作保持固定。
- 最终版本展开横屏、左/右侧栏各方向的截图。
- 最大 Dynamic Type、VoiceOver 和实体硬件。

最新任务已明确不继续测试编辑取消的数据语义；没有对相关语义作通过结论。

## 工具阻塞与边界

1. 原生 Xcode `DeviceInteractionSynthesize` 的采集在部分时刻能够返回真实截图及 app 层级，另一些时刻返回黑图或失效会话；即使改用持久 MCP bridge，仍发生 `Session not found`。无 workspace 的会话返回 `NotRun`，但同次层级中可看到 app PID，不能把该字段当作 app 未运行的单独证据。
2. 第三方 AXe snapshot 能读到元素，但 tap 曾返回成功而画面不变；没有据此宣称按钮功能正常。
3. CUA 曾成功切换资料库到乐事详情，得到修复前遮挡截图。最终重新安装后，Device Hub 的 CUA 层级只剩设备外框、无应用子树；两次基于实际截图的点击没有改变画面。
4. 尝试重新连接时，Device Hub 前台窗口切换到了另一个模拟器；再次选择菜单中的 Duo 项报 `elementHasNoFrame`。没有修改或操作该其他模拟器中的应用。
5. 按 device-interaction 的重试上限停止重复点击。工具失败不作为应用功能失败结论。最终需要恢复稳定设备控制后补齐上述交互和滚动前后截图。
