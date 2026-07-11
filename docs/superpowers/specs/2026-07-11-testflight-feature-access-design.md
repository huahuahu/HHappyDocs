# TestFlight 功能访问设计

## 目标

让所有通过 TestFlight 安装的用户都能使用受订阅限制的“快乐时刻”功能，即使其沙盒订阅已经过期。同时保留 StoreKit 的真实订阅状态和全部购买界面，让测试人员仍然可以测试购买、续订、过期和恢复购买流程。

通过 App Store 正式发布的版本必须继续要求用户持有有效订阅。

## 当前行为

`RecordSubscriptionStatusModifier` 负责获取并缓存 `RecordSubscriptionStatus`，随后通过 SwiftUI 环境注入该状态。`AddMomentNavigationView` 直接读取这个状态，以决定进入新增时刻流程、显示首次订阅推广，还是展示订阅页面。设置页和购买页面也读取同一个状态，用于显示用户真实的 StoreKit 订阅情况。

当前这一个值同时代表了两个不同概念：

- 购买界面需要展示的 StoreKit 订阅状态。
- 用户是否有权使用订阅功能。

如果在 TestFlight 中伪造一个已订阅状态，虽然可以解锁功能，但也会让测试人员看不到真实的沙盒订阅状态。新设计将这两个概念分开。

## 设计

### 分发来源判定

在 `HDiaryIAP` 中增加一个轻量的分发来源判定器。只有同时满足以下条件时，才判定为 `.testFlight`：

- 当前进程运行在真机上，而不是模拟器上。
- `Bundle.main.appStoreReceiptURL?.lastPathComponent` 等于 `sandboxReceipt`。
- 已安装的 App 包中不存在 `embedded.mobileprovision`。

这组条件可以区分 TestFlight 安装、正式 App Store 收据、Xcode StoreKit Testing，以及开发或 Ad Hoc 安装。Apple 可以通过 `AppTransaction.environment` 提供交易服务器环境，但只检查沙盒环境仍然不够，因为开发环境中的沙盒交易同样属于 sandbox。

判定器接收收据文件名、是否存在嵌入式描述文件以及是否运行于模拟器作为输入。正式运行时由 App 包和编译环境提供这些值；单元测试则传入明确的测试值。

判定采用保守策略。任何缺失或不符合预期的信息都返回 `.other`，继续要求真实订阅，避免意外给正式版本授予权限。

### 功能访问策略

在 SwiftUI 环境中增加一个独立的“时刻功能访问权限”值。该值只在内存中通过以下信息计算：

- 真实的 `RecordSubscriptionStatus`。
- 当前 App 的分发来源。

满足以下任一条件时允许访问功能：

1. 真实状态为月度或年度订阅，并且已经通过现有交易校验。
2. 当前分发来源为 TestFlight。

TestFlight 权限覆盖不会被编码到 `recordSubscriptionStatusData`，也不会写入其他持久化存储。因此，用户以后安装正式 App Store 版本时，不会继承已经失效的 TestFlight 解锁状态。

### UI 数据流

`RecordSubscriptionStatusModifier` 继续作为真实 StoreKit 状态的根提供者，同时注入计算得到的功能访问权限。

`AddMomentNavigationView` 在两个限制判断中改为检查功能访问权限，而不是直接匹配 `.notSubscribed`：

- TestFlight 用户可以直接进入新增时刻流程，不会遇到订阅阻挡页面。
- TestFlight 用户在该流程中也会跳过首次订阅推广页面。
- 正式版本用户继续沿用当前的免费数量限制、订阅推广和订阅页面逻辑。

购买相关界面继续使用真实订阅状态：

- `RecordSubscriptionBuyCell` 继续显示在设置页中，并根据 StoreKit 状态显示当前文案。
- `RecordSubscriptionView` 继续展示 StoreKit 商品。
- 购买、恢复购买、续订、过期和升级行为均保持不变。

这样可以满足已经选择的行为：TestFlight 用户拥有功能权限，同时仍可主动进入 IAP 流程进行测试。

## 错误处理与日志

分发来源判定为同步操作，不依赖网络。如果收据 URL 不存在、收据文件名不符合预期，或 App 中存在开发描述文件，判定器都会返回 `.other`。

在安装订阅环境时记录最终的分发来源类别，但不记录收据内容或其他购买数据。

StoreKit 状态获取失败时继续沿用当前处理方式。在 TestFlight 中，即使无法加载沙盒订阅状态，基于分发来源计算的功能权限仍允许用户使用受限功能；购买界面继续显示现有 StoreKit 流程能够提供的真实状态。

## 测试

在 `HDiaryIAPTests` 中为纯判定逻辑增加以下单元测试：

- 真机、`sandboxReceipt`、无嵌入式描述文件时判定为 TestFlight。
- 正式 `receipt` 不判定为 TestFlight。
- `sandboxReceipt` 但存在嵌入式描述文件时不判定为 TestFlight。
- 模拟器上的 `sandboxReceipt` 不判定为 TestFlight。
- 收据不存在时不判定为 TestFlight。

增加功能访问策略测试：

- TestFlight 加 `.notSubscribed` 时允许访问功能。
- 非 TestFlight 加 `.notSubscribed` 时拒绝访问功能。
- 月度和年度订阅在任意分发来源中都允许访问功能。

实现将遵循测试驱动开发：先添加判定器和访问策略的失败测试，确认测试因缺少目标行为而按预期失败；然后添加最小化的正式实现，最后重新运行相关 Swift Package 和 Xcode 工程测试。

## 不在本次范围内

- 伪造或持久化已付费订阅状态。
- 隐藏、禁用或修改 StoreKit 购买界面。
- 修改沙盒商品有效期或 App Store Connect 配置。
- 增加服务端收据验证。
- 在没有有效订阅时解锁 Debug、模拟器、开发、Ad Hoc 或正式 App Store 安装。

## 成功标准

- TestFlight 用户即使没有当前有效的沙盒订阅，也可以新增超过免费数量限制的时刻。
- 同一 TestFlight 用户仍然可以打开设置页并测试真实 IAP 流程。
- 订阅文案继续反映 StoreKit 的真实状态。
- 没有有效订阅的正式 App Store 用户仍然受到功能限制。
- TestFlight 权限覆盖不会被持久化，也不会泄漏到以后安装的正式版本中。
