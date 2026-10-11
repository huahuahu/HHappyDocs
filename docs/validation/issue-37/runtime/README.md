# Issue #37 小组件运行验证

验证时间：2026-10-08 06:59–07:11（Asia/Shanghai）。

## 环境与数据

- 工程：`HDiary.xcodeproj`，scheme `HDiary`，Debug bundle `com.tiger.suzhou.HDiary-Debug`。
- 模拟器：配置指定的 `hdiary 17pro`，UDID `A044BA15-7770-48E6-8E28-E2123A772ACD`，iOS 26.5。
- 系统语言为简体中文，系统外观原为 Dark，默认文字大小。
- 使用模拟器既有日记及参与者数据。共享偏好的 `swiftDataContainerType=1`，与源码 `.local` 对应，当前 Debug 容器关闭 CloudKit。
- 没有新增、修改或删除任何日记、参与者、头像数据；没有重置 App 或模拟器。
- 原主屏已有两枚中号“所有人”小组件；本次将上方一枚改为大号并选择“宝宝”（已有黑白照片头像），下方保留中号“所有人”。

## 已通过

| 验证 | 实际结果 | 证据 |
| --- | --- | --- |
| 中号显示 | 显示标题“乐事”、主题图标、3 条乐事及同行日期；中英文标题均可读 | `01-medium-all-dark.jpg` |
| 大号显示 | 从系统长按菜单切换“大尺寸小组件”后显示 6 条乐事，日期置于标题下方；未见重叠或裁切 | `02-large-all-dark.jpg` |
| 所有人/指定参与者配置 | 打开系统编辑面板，原值为“所有人”；选择既有“宝宝”后，头部显示照片头像和姓名，乐事列表变为该参与者的记录 | `03-config-selected-participant.jpg`、`04-large-selected-dark.jpg` |
| 配置刷新 | 关闭配置面板后出现短暂重载，随后列表从所有人记录变为“宝宝”记录；例如第一条从“艺术画廊之旅”变为“探索城市美食” | `02-large-all-dark.jpg` 对照 `04-large-selected-dark.jpg` |
| 点击打开 App | 点击大号小组件后打开 HDiary 的“乐事”页 | `05-widget-opens-app.jpg` |
| 最终版深色显示 | 最后头像修复重新构建安装后，再次看到指定参与者照片、大号6条及中号3条 | `06-final-build-dark.jpg` |
| 系统色调 | 使用主屏“自定义 → 色调”（该模式的“浅色”选项），照片被系统去饱和，头像轮廓、姓名、正文及日期均可辨；无重叠或裁切 | `07-final-build-tinted.jpg` |
| 系统透明 | 使用主屏“自定义 → 透明”（该模式的“浅色”选项），大小两枚小组件均透出墙纸，文字、日期及照片仍可辨 | `08-final-build-clear.jpg` |
| 恢复外观 | 回到主屏“自定义 → 默认”，按钮恢复“调暗墙纸”，即墙纸未处于调暗状态；系统 Dark 未改 | `09-restored-default-appearance.jpg` |

头像为模拟器既有照片，覆盖原图渲染分支。系统符号默认头像在深色下的修复由主线程 Preview 另行验证，本次主屏没有宣称覆盖该分支。

截图 01–05 来自首次构建（07:00前后）；06–09 来自包含最后 `.renderingMode(participant.avatar.isSymbolImage ? .template : .original)` 修复的最终构建。截图通过 XcodeBuildMCP screenshot 工具获取，其自动优化为 368×800 JPEG；没有拼接或人工修改图片。

## 构建结果

1. XcodeBuildMCP `build_run_sim` 首次构建、安装、启动成功，用时 151.1 秒，PID 30125。该次构建有工程既有弃用/并发警告。
2. 最终头像修复后再次 `build_run_sim` 成功，用时 110.4 秒，PID 34918；工具返回 warnings=[]、errors=[]。
3. 最终构建日志：`~/Library/Developer/XcodeBuildMCP/workspaces/HHappyDocs-bcf727e6e329/logs/build_run_sim_2026-10-07T23-03-46-202Z_pid26687_a614f26f.log`。

## 工具限制及未验证边界

- 优先尝试 Xcode MCP `DeviceInteractionStartWorkspaceSession`。先前 `XcodeOpenWorkspace` 返回 My Mac，随后已显式切回 `hdiary 17pro`；两次 workspace session 均报 `Cannot select specified device`，eligible devices 只包含 iOS 27/27.1。Xcode run-destination 列表本身仍将 hdiary 17pro/iOS26.5 标为 eligible。因此按仓库规则使用 XcodeBuildMCP 对同一 UDID 构建及交互，没有换设备。
- XcodeBuildMCP 的部分普通 tap、Home、scroll 工具返回成功但界面未变。改用同一新鲜层级目标的 touch down/up（0.12秒）可以完成主屏菜单操作；`gesture(scroll-right)` 配合显式 402×874 点尺寸可翻页。
- App 内部及系统参与者配置面板的 `snapshot_ui` 没有可用子控件。参与者选择使用 CUA 的 Device Hub 紧凑模拟器窗口完成，点击后重新截屏确认。
- 后续 CUA 返回：`The Mac is locked and automatic unlock could not unlock it. Ask the user to unlock the Mac manually before continuing.` 未绕过 Mac 锁屏。仍通过模拟器服务完成了系统色调、透明、默认恢复。
- **数据内容变更触发的刷新未验证**：没有创建/编辑一条日记再观察 Widget 更新。上述“配置刷新”不能替代该证据。写入同步与 reload 调用顺序由主线程的既有回归测试另行覆盖。
- 没有本次实际新增小组件的证据：利用了既有两枚小组件，实际验证了升级后显示及 medium→large 系统尺寸切换。
- 没有系统 Light 外观、真机、默认符号头像主屏运行、最大 Dynamic Type 主屏运行的证据。

## 结束状态

- 外观已恢复原来的系统 Dark + 主屏“默认”模式及正常墙纸亮度。
- 两枚原有 Widget 仍保留：上方大号“宝宝”，下方中号“所有人”。尺寸和配置的改变保留供查看，未删除小组件。
- HDiary App 由 `stop_app_sim` 正常停止，前台停留在主屏；没有崩溃证据。
- 没有成功建立 Xcode Device Interaction session，因而没有未关闭的此类会话。
- 07:11 已向主线程释放模拟器用于其后续测试。
