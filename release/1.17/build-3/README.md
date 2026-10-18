# HDiary 1.17（3）内部 TestFlight

核验时间：2026-10-19T06:51:40+08:00。

乐事详情在横屏时不再按视口高度缩小图片：TabView 按整组图片的最大等比例高度布局，总高上限为容器宽度的 4/3。ScrollView 通过 onGeometryChange 直接读宽，正文采用弹性宽度。

- 功能 PR：[#70](https://github.com/huahuahu/HHappyDocs/pull/70)，已合并至 `753b0663515472a8bfcd07a3fd4a87c09f344c04`。
- 归档源码：`980b9f59e2813ee0705db713f1dc9ec8dbd427c7`，只在该合并基础上增加 build 号及测试说明。
- App：`6470147729` / `com.tiger.suzhou.HDiary`。
- Build ID：`175a1614-5dea-4c69-9de5-d7fbbb7369ed`。
- 远端状态：`VALID` / `IN_BETA_TESTING`；已核验内部组 `huahuahu-itnernal` 的构建关联。
- 中英文 What to Test 已写入并回读一致。TestFlight 校验为 0 错误、0 警告、0 阻塞。

## 制品与验证

Release 归档和 IPA 保存在被忽略的 `build/releases/1.17/3/`。App 与 Widget 均为 1.17（3），分发签名、Production CloudKit、App Groups、dSYM UUID 与 Debug 入口排除校验通过。

IPA SHA-256：`5cfb0f57d59abe5e49e681e2e9edc5872f41516bb21397ececd607ea8ad65a02`。

本地修复验证共 24 个快照参数场景通过，最终模拟器横屏媒体父容器为 750×1000 pt，旋转后宽度正确更新。具体边界见 [validation.md](validation.md)，制品校验见 [ipa-verification.json](ipa-verification.json)。未通过 TestFlight 真机安装验证，也未将模拟器尺寸检查视为 Quick Look/GIF 的完整回归。

功能 PR 合并时未报告必需检查，GitGuardian 已通过；构建及两台设备快照 CI 的最后已知状态单独保存在 [status.json](status.json)，不能把本地通过表述为全部 CI 通过。

本次仅内部 TestFlight，未创建 App Store 1.17 版本、未提交正式或外部 Beta 审核，`MANUAL` 策略在本阶段不适用。正式版本 tag 暂缓。
