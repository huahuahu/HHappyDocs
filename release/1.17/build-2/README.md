# HDiary 1.17（2）内部 TestFlight 发布

核验时间：2026-10-18T18:34:38+08:00（Asia/Shanghai）。

- App：HDiary，`6470147729`，`com.tiger.suzhou.HDiary`。
- 版本 / build：**1.17（2）**。
- Build ID：`824a75a7-f501-4dc6-8405-22ec5a2324ab`。
- 远端状态：`VALID`、`IN_BETA_TESTING`，未过期。
- 内部测试组：`huahuahu-itnernal`（`4aa0f2b2-2bb7-40c7-a4a9-7749b45eb3e2`），关联已回读确认。
- 中英文 What to Test 已写入并逐字回读核对；TestFlight 校验 0 errors、0 warnings、0 blocking。
- 源码：`b35fce33009a76b17327448d2b774b48e3eec2e5`，基于最新远程 main `793f868`，本次仅递增 build。

## 本次变化

包含 PR #67 的乐事详情图片预览改进：根据窗口空间和图片比例调整预览，多图使用固定容器，保留分页、GIF 标记和 Quick Look，并修复窄窗口大字号内容越界。与上一 TestFlight 构建相比没有数据模型变更。

## 验证

- 当前源码的 iPhone 17 Pro / iOS 27.0 通用测试：145 通过、0 失败；3 项仅适用于 macOS，未运行。
- Release archive 和 IPA 导出成功。App 与 Widget 均为 1.17（2），正式 Bundle ID、发行签名、Production CloudKit、App Groups、dSYM UUID 均核验；Release 不包含调试截图或媒体夹具入口。
- Debug 模拟器交互通过：横图切换至竖图时容器稳定，Quick Look 打开原图并保持到主动关闭，关闭后仍在第 2/6 页，滚动后可完整到达图片底部与页码。见 [模拟器报告](simulator-smoke.md)。
- 远程 main 的 iOS 构建与测试 CI 已通过；截至上述核验时间，iOS snapshots CI 仍在运行。当前发布没有重复执行完整快照计划。
- 没有通过 TestFlight 在真机安装；模拟器 Debug 证据不代表 Release IPA 已安装验证。

## 制品与记录

- IPA：`build/releases/1.17/2/HDiary.ipa`。
- Archive：`build/releases/1.17/2/HDiary.xcarchive`，包含 dSYM。
- IPA SHA-256：`c0e37b2dd1820b75f7e19b011b3f6c142fd7b083af4ead7dc399a5f939b983d2`。
- 完整日志、远端原始回执、测试结果和交互截图保存在被忽略的 `build/releases/1.17/2/`。
- [状态记录](status.json)、[安装包校验](ipa-verification.json)、[中文测试说明](testflight-notes.zh-Hans.txt)、[英文测试说明](testflight-notes.en-US.txt)。

本次范围为内部 TestFlight。外部状态为 `READY_FOR_BETA_SUBMISSION`，未提交外部 Beta 审核或 App Store 正式审核；当前阶段不适用 `MANUAL` 发布策略。正式版本 tag 暂缓。本次版本号与发布资料在本地提交，未推送 GitHub。
