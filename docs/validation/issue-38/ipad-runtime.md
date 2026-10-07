# Issue 38 iPad 运行验证

验证日期：2026-10-06。此记录由 iPad 验证代理维护。

## 环境与隔离

- 已启动模拟器：iPad Pro 13-inch (M5)，iOS 26.5，UUID `2D15C1CC-968A-4A02-B13A-20166E188204`。
- 项目配置已读取：`HDiary.xcodeproj` / `HDiary`；未改 `.xcodebuildmcp/config.yaml`，未切 Xcode scheme，未执行构建。
- native Xcode DeviceInteraction 在主代理探测时未列出此 iOS 26.5 设备，因此使用 xcodebuildmcp 2.7.0 CLI。
- 本代理先调用 MCP `session_show_defaults`，返回 `MCP tool xcodebuildmcp/session_show_defaults is not available to the model`。CLI 未暴露 session defaults 管理子命令，所以每一步都显式传入上述 iPad UUID，不依赖默认模拟器。
- 安装产物：`/Users/tigerguo/Library/Developer/Xcode/DerivedData/HDiary-dqemprmzojrldyfqudhljzibrvin/Build/Products/Debug-iphonesimulator/HDiary.app`。
- Bundle ID：`com.tiger.suzhou.HDiary-Debug`，启动 PID：49696。
- 启动参数：`-swiftDataContainerType 2 -bypassIPRestriction YES -appLockEnabled NO -AppleLanguages (zh-Hans) -AppleLocale zh_CN`。使用内存样本，不写用户正式日记数据。

## 当前确认

安装、启动成功。语义快照可读取“乐事 / 资料库 / 设置”页签、“新建乐事”、搜索框，以及昨天 1、最近 7 天 1、九月 10、八月 8 分组。截图中横屏列表与顶部控件可见，没有发现此画面文字重叠或裁切。

## 横屏交互工具限制

1. `xcodebuildmcp ui-automation tap` 对最新语义快照中的“新建乐事”目标两次均返回 success，但再次快照和截图都仍停留列表。
2. 对“昨天”分组的点击同样返回 success，但分组未展开。
3. AXe `describe-ui` 的根 frame 为 1376 × 1032，与实际横屏图片一致；“新建乐事”的解析点为 (1083, 54)。
4. 进一步使用 bundled AXe `tap --tap-style physical` 点击同一语义目标，以及基于当前横屏尺寸计算的两种 90 度坐标映射 (54, 293) / (978, 1083)，均未观察到界面变化。
5. 无 AX 权限拒绝、应用退出或崩溃证据。此处只能确认事件注入工具报告成功、实际 UI 未发生变化，不能据此认定“新建乐事”业务逻辑失败。
6. AXe CLI 和 xcodebuildmcp CLI 的可用命令均未提供后台 orientation 操作。暂待其他验证代理释放前台设备操作后协调竖屏验证。

## 证据

- `ipad-list-landscape.png`：来自 bundled AXe 的 PNG 截图；原始 framebuffer 为侧转的竖向像素，已顺时针旋转 90 度以便查看，未改画面内容。
- `ipad-list-landscape.snapshot.json`：xcodebuildmcp rs/1 语义快照，PID 对应 app 已启动后的列表状态。

列表详情、新建、编辑、标题/正文、键盘、保存、取消、返回目前均不能记为交互通过。后续竖屏结果将在本文件补充。
