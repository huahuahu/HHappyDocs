# iPhone 17 Pro / iOS 26.5 验证记录

- 日期：2026-10-06。
- 模拟器：`hdiary 17pro`，`A044BA15-7770-48E6-8E28-E2123A772ACD`。
- 产物：`/Users/tigerguo/Library/Developer/Xcode/DerivedData/HDiary-dqemprmzojrldyfqudhljzibrvin/Build/Products/Debug-iphonesimulator/HDiary.app`。
- Bundle ID：`com.tiger.suzhou.HDiary-Debug`。
- 启动参数：`-swiftDataContainerType 2 -bypassIPRestriction YES -appLockEnabled NO -AppleLanguages (zh-Hans) -AppleLocale zh_CN`。
- 本轮未重新构建、未修改产品源码、未修改共享 `.xcodebuildmcp/config.yaml`。

## 已验证

1. XcodeBuildMCP CLI 安装最新真实产物成功。
2. 使用上述参数启动后，可以捕获中文“乐事”月列表。列表、搜索栏、添加按钮、三个 Tab 均显示完整，初始截图未见重叠。
3. 改用 MCP 非持久化 `issue38-phone` profile 启动，PID `68512` 持续存活；恢复验证时 `ps` 仍显示进程和完整安全启动参数。

## 工具限制与未验证项

- CLI 首次启动 PID `57264` 后，在尝试点击“新建乐事”时观察到 SpringBoard，进程已经退出；未发现新 HDiary `.ips` 报告，运行日志无 Swift fatal。尚不能将此认定为应用崩溃，CLI 启动会话/日志 helper 生命周期是待排除因素。
- MCP 启动后，`tap(elementRef: "e17")` 返回成功，报告点击位置 `(364, 84)`；但操作返回的 UI capture 和随后单独采集的 snapshot 均保持 `screenHash: 1yeiq3u`，仍显示月列表。“新建乐事”未实际打开。
- 未反复重试坐标，未切换 macOS 前台。等待前台设备操作资源释放后继续。
- **创建、标题/正文输入、收起键盘、保存、详情、编辑取消、照片导入和 QuickLook 均尚未实际验证。**

## 文件

- `iphone-17pro-list-ios26.5.jpg`：最新 MCP 启动的月列表截图。
- `iphone-17pro-list-ios26.5-snapshot.json`：对应语义 UI snapshot。
