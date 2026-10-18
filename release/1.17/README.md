# HDiary 1.17（1）TestFlight

核验时间：2026-10-14T22:25:55+08:00。

本次使用最新 main 的应用源码，增加筛选、标签排序菜单图标，将媒体筛选文案改为「有照片或视频」。1.16 已在 App Store 上线，因此本次递增至 1.17（1）。只发布内部 TestFlight。

| 项目 | 值 |
| --- | --- |
| App ID | `6470147729` |
| Bundle ID | `com.tiger.suzhou.HDiary` |
| Build ID | `d5e34417-4993-479b-a4f6-da4aa4311948` |
| 处理状态 | `VALID` |
| 内部测试状态 | `IN_BETA_TESTING` |
| 测试组 | `huahuahu-itnernal`，已回读确认关联 |
| 外部测试状态 | `READY_FOR_BETA_SUBMISSION`，本次未提交外部 Beta 审核 |
| 最新 main | `8dee945b295011a405ad1d74dfa462874ce42c75` |
| 归档时源码 | `848c90ba526dac23b6f5a0189ace53fe4a97c847` |
| 与归档输入一致的版本提交 | `9369f7d562720c780750834aae235440c9559f1d` |

归档后 main 新增了仅修改 `.github/workflows/snapshots.yml` 的提交。本地版本号提交已 rebase 到该 main；逐文件比较确认两个提交的 App、Widget、依赖、资源、配置、脚本及 lockfile 等归档输入完全一致。

## 制品和验证

- IPA：`build/releases/1.17/1/HDiary.ipa`。
- Archive 与 dSYM：`build/releases/1.17/1/HDiary.xcarchive`。
- IPA SHA-256：`5566726b747385f3d578989f58a3a90fc5d784791f28e269da4c78a8c472cf38`。
- App 和 Widget 包内版本均为 1.17（1）；分发签名、生产 CloudKit / App Groups 权限与 dSYM UUID 匹配已验证。
- Release 二进制不含 DEBUG 截图入口；JournalingSuggestions 保持弱链接。
- 原生 Xcode 在配置的 iPhone 17 Pro / iOS 27.0 上执行现有测试：145 通过、0 失败，3 项 macOS 专用测试未运行。
- DEBUG 离线 fixture 启动、乐事列表、资料库 tab 切换、标签列表和计数通过。筛选入口未在 fixture 中提供；原生交互 session 在排序检查前失效，因此未验证完整菜单操作。一次短暂后台/黑屏在重新激活后恢复，原因未确定，未建立崩溃证据。详细记录为 `build/releases/1.17/1/smoke/report.md`。
- 未通过 TestFlight 在真机安装验证。上述 `IN_BETA_TESTING` 仅证明内部可分发状态。
- 中英文 What to Test 已保存并回读一致。`asc validate testflight` 为 0 错误、0 警告、0 阻塞。
- 近期应用源码提交的 iPhone 快照 CI 成功，Duo 任务超时，主构建测试任务被取消；此次本地测试和签名归档另有独立证据。

首次导出因系统与 Homebrew rsync 参数冲突失败，单次限制 PATH 为系统工具后导出成功；未改源码、系统 Git 配置或签名配置。原始日志、校验脚本和远端回执保存在被忽略的 `build/releases/1.17/1/`。

本次未创建 1.17 App Store 版本、未提交正式审核，`MANUAL` 策略不适用于当前 TestFlight-only 阶段。正式版本 tag 暂缓；本次本地版本及发布资料提交尚未推送。后续正式提审需按项目发布技能设定并回读 `releaseType=MANUAL`。
