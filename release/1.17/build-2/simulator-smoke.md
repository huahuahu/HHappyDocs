# HDiary 1.17 (2) 模拟器 smoke 报告

原始截图、hierarchy 和工具回执位于仓库根目录下 `build/releases/1.17/2/smoke/`；下列证据文件名均相对此目录。

- 时间：2026-10-18 18:29–18:33（Asia/Shanghai）。
- 源码：本次发布工作区 b35fce3；本次使用原生 Xcode MCP 构建并启动 **Debug** 应用 `com.tiger.suzhou.HDiary-Debug`。
- 工程：HDiary.xcodeproj；scheme：HDiary。
- 模拟器：HDiary Snapshot iPhone 17 Pro，UDID `040ECFE5-4ED3-4795-AC27-23490CF57596`，竖屏，402 × 874 pt。
- 启动环境：仅本次运行传入 `HDIARY_MEDIA_PREVIEW=mixed`，使用独立内存 fixture 和正式详情路由；未编辑 scheme、源码、配置或用户数据库。

## 结果

本次范围内通过，未观察到确凿的功能或布局 bug。所有采集状态为 Running，应用 PID 保持 63477。

1. 详情页正常显示标题、日期、说明与横图，图片边框、四角及圆形完整。证据：`01-first-page.png`、对应 hierarchy。
2. 从最新 hierarchy 的图片 hitPoint `(201, 585.5)` 向左滑动，成功由第 1 页进入第 2 页（竖图）。两页分页容器均为 `(0, 358.3, 402, 498.3)` pt，图片交互区域均为 `(0, 358.3, 402, 454.3)` pt；页面切换未引起容器跳动。证据：`01-first-page-hierarchy.txt`、`02-second-page-hierarchy.txt` 及截图。
3. 点击第二页图片 hitPoint，打开 Quick Look；等待界面稳定后，实见完整 PORTRAIT 600 × 900 原图。Quick Look 一直保持到主动关闭。证据：`04-quick-look-settled.png` 和 hierarchy 中 `QLPreviewControllerView` / Image canvas。
4. 轻点原图显示工具按钮，读取最新关闭按钮 hitPoint `(38, 84)` 后关闭，返回仍为第 2 页；容器位置与大小保持不变。证据：`05-quick-look-controls-hierarchy.txt`、`06-return-page-two.png` 和对应 hierarchy。
5. 向上滚动后，竖图底边、四角与第 2 页指示器完整可见；容器随导航栏收起后可用视口变化重算为 402 × 540 pt，图片区域 402 × 496 pt。这是纵向滚动导致的视口变化，与翻页无关。证据：`07-scrolled-page-two.png` 和对应 hierarchy。
6. 已调用 DeviceInteractionEndSession 并读回成功结果。证据：`08-session-end-response.json`。

首屏图片底部与页码处于浮动 Tab 栏覆盖范围，纵向滚动后可完整到达，符合此长内容页面的滚动表现。`03-quick-look.png` 与 `05-quick-look-controls.png` 处于系统过渡帧，稳定 Quick Look 图像以 `04-quick-look-settled.png` 为准。

## 证据边界

本报告证明当前 b35fce3 源码的 **模拟器 Debug fixture** 详情路由交互。没有安装或运行本次 Release IPA，没有通过 TestFlight 真机安装，不证明 Apple 处理、分发或真机行为。未验证 GIF 动画、其余四页、横屏、Duo、iPad、真实用户数据、云同步或完整回归。发布上传及处理状态由主任务独立核实。

各步骤保存了原始 bridge response JSON、完整 screenshot、hierarchy 和日志（如有）。截图均实际查看后作出以上判断。
