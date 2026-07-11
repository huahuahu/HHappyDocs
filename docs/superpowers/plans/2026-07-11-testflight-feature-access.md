# TestFlight 功能访问实现计划

> **面向执行代理：** REQUIRED SUB-SKILL: 使用 `subagent-driven-development`（推荐）或 `executing-plans` 逐项执行本计划。所有步骤使用复选框（`- [ ]`）跟踪。

**目标：** TestFlight 安装始终拥有“快乐时刻”订阅功能权限，同时继续展示和使用 StoreKit 的真实订阅状态与购买流程。

**架构：** 在 `HDiaryIAP` 内新增一个同步、保守且可单元测试的分发来源判定器，再用独立策略把“真实订阅状态”和“功能访问权限”组合成布尔值。SwiftUI 根订阅修饰器注入真实状态与派生权限，新增时刻页面只使用派生权限做门禁，购买页面继续只使用真实状态。

**技术栈：** Swift 6、SwiftUI、StoreKit 2、XCTest、Swift Package、XcodeBuildMCP。

## 全局约束

- iOS 最低版本保持 `17.0`，Swift Package 平台保持 iOS 17、macOS 14。
- 不增加第三方依赖，也不修改 App Store Connect 或 StoreKit 商品配置。
- `recordSubscriptionStatus` 和 `recordSubscriptionStatusData` 必须继续只表示真实 StoreKit 状态。
- TestFlight 权限只能在内存中派生，不能写入 UserDefaults 或其他持久化存储。
- `RecordSubscriptionBuyCell`、`RecordSubscriptionView`、恢复购买和升级流程保持不变。
- Debug、模拟器、开发、Ad Hoc 和正式 App Store 安装不能因本功能被误解锁。
- 分发信息缺失或不符合预期时必须返回 `.other`，保守执行真实订阅限制。
- 遵守仓库 `AGENTS.md`：构建或测试前先调用 XcodeBuildMCP 的 `session_show_defaults`；若与 `.xcodebuildmcp/config.yaml` 不一致，调用 `session_set_defaults`，使用绝对工程路径 `/Users/tigerguo/.codex/worktrees/d1bb/HHappyDocs/HDiary.xcodeproj`、scheme `HDiary`、模拟器 ID `A044BA15-7770-48E6-8E28-E2123A772ACD`。
- 所有构建和测试使用 XcodeBuildMCP，不直接调用 `xcodebuild`、`xcrun` 或 `simctl`。

## 文件结构

- 新建 `HDiaryLibrary/Sources/HDiaryIAP/Model/AppDistribution.swift`：只负责把收据、描述文件和模拟器信息分类为 TestFlight 或其他来源。
- 新建 `HDiaryLibrary/Sources/HDiaryIAP/Model/RecordFeatureAccess.swift`：只负责根据真实订阅状态与分发来源计算功能权限，并声明 SwiftUI 环境值。
- 修改 `HDiaryLibrary/Sources/HDiaryIAP/View/RecordSubscriptionModifier.swift`：注入真实状态和派生权限，不改变订阅缓存。
- 修改 `HDiaryLibrary/Sources/HDiaryAppFeature/Moments/AddMoment/AddMomentNavigationView.swift`：使用功能权限决定新增时刻、推广页或订阅页。
- 修改 `HDiaryLibrary/Tests/HDiaryIAPTests/HDiaryIAPTests.swift`：覆盖分发来源和功能权限策略。
- 新建 `HDiaryLibrary/Tests/HDiaryAppFeatureTests/AddMomentAccessTests.swift`：覆盖新增时刻页面的纯路由决策。

---

### 任务 1：TestFlight 分发来源判定器

**文件：**

- 新建：`HDiaryLibrary/Sources/HDiaryIAP/Model/AppDistribution.swift`
- 修改：`HDiaryLibrary/Tests/HDiaryIAPTests/HDiaryIAPTests.swift:1-19`

**接口：**

- 使用：`Bundle.main.appStoreReceiptURL`、`Bundle.main.url(forResource:withExtension:)`、`targetEnvironment(simulator)`。
- 提供：`AppDistribution.testFlight`、`AppDistribution.other`、`AppDistribution.classify(receiptLastPathComponent:hasEmbeddedMobileProvision:isSimulator:) -> AppDistribution`、`AppDistribution.current`。

- [ ] **步骤 1：确认 XcodeBuildMCP 会话默认值**

调用 `session_show_defaults`。预期工程为 `/Users/tigerguo/.codex/worktrees/d1bb/HHappyDocs/HDiary.xcodeproj`，scheme 为 `HDiary`，模拟器 ID 为 `A044BA15-7770-48E6-8E28-E2123A772ACD`。

若任一值缺失或不同，调用 `session_set_defaults`，参数使用：

```json
{
  "projectPath": "/Users/tigerguo/.codex/worktrees/d1bb/HHappyDocs/HDiary.xcodeproj",
  "scheme": "HDiary",
  "simulatorId": "A044BA15-7770-48E6-8E28-E2123A772ACD",
  "simulatorName": "hdiary 17pro"
}
```

预期：再次调用 `session_show_defaults` 后显示上述值。

- [ ] **步骤 2：用分发矩阵替换占位测试**

把 `HDiaryIAPTests.swift` 替换为：

```swift
#if os(iOS)

  @testable import HDiaryIAP
  import XCTest

  final class HDiaryIAPTests: XCTestCase {
    func testPhysicalSandboxReceiptWithoutProfileIsTestFlight() {
      let distribution = AppDistribution.classify(
        receiptLastPathComponent: "sandboxReceipt",
        hasEmbeddedMobileProvision: false,
        isSimulator: false
      )

      XCTAssertEqual(distribution, .testFlight)
    }

    func testProductionReceiptIsNotTestFlight() {
      let distribution = AppDistribution.classify(
        receiptLastPathComponent: "receipt",
        hasEmbeddedMobileProvision: false,
        isSimulator: false
      )

      XCTAssertEqual(distribution, .other)
    }

    func testEmbeddedProvisioningProfileIsNotTestFlight() {
      let distribution = AppDistribution.classify(
        receiptLastPathComponent: "sandboxReceipt",
        hasEmbeddedMobileProvision: true,
        isSimulator: false
      )

      XCTAssertEqual(distribution, .other)
    }

    func testSimulatorIsNotTestFlight() {
      let distribution = AppDistribution.classify(
        receiptLastPathComponent: "sandboxReceipt",
        hasEmbeddedMobileProvision: false,
        isSimulator: true
      )

      XCTAssertEqual(distribution, .other)
    }

    func testMissingReceiptIsNotTestFlight() {
      let distribution = AppDistribution.classify(
        receiptLastPathComponent: nil,
        hasEmbeddedMobileProvision: false,
        isSimulator: false
      )

      XCTAssertEqual(distribution, .other)
    }
  }

#endif
```

- [ ] **步骤 3：运行测试并确认按预期失败**

运行：

```bash
xcodebuildmcp simulator test \
  --project-path /Users/tigerguo/.codex/worktrees/d1bb/HHappyDocs/HDiary.xcodeproj \
  --scheme HDiary \
  --simulator-id A044BA15-7770-48E6-8E28-E2123A772ACD \
  --extra-args "-only-testing:HDiaryIAPTests/HDiaryIAPTests"
```

预期：失败，编译器报告找不到 `AppDistribution`。如果失败原因是模拟器或工程默认值，先修正执行环境，再重新运行，直到失败原因只剩目标类型尚未实现。

- [ ] **步骤 4：添加最小分发判定实现**

新建 `AppDistribution.swift`：

```swift
import Foundation

enum AppDistribution: Equatable, Sendable {
  case testFlight
  case other

  static func classify(
    receiptLastPathComponent: String?,
    hasEmbeddedMobileProvision: Bool,
    isSimulator: Bool
  ) -> Self {
    guard !isSimulator,
          receiptLastPathComponent == "sandboxReceipt",
          !hasEmbeddedMobileProvision
    else {
      return .other
    }

    return .testFlight
  }

  static var current: Self {
    #if targetEnvironment(simulator)
      let isSimulator = true
    #else
      let isSimulator = false
    #endif

    return classify(
      receiptLastPathComponent: Bundle.main.appStoreReceiptURL?.lastPathComponent,
      hasEmbeddedMobileProvision: Bundle.main.url(
        forResource: "embedded",
        withExtension: "mobileprovision"
      ) != nil,
      isSimulator: isSimulator
    )
  }
}
```

- [ ] **步骤 5：重新运行分发判定测试**

运行与步骤 3 相同的 XcodeBuildMCP 命令。

预期：`HDiaryIAPTests/HDiaryIAPTests` 中 5 个测试全部通过。

- [ ] **步骤 6：提交分发判定器**

```bash
git add \
  HDiaryLibrary/Sources/HDiaryIAP/Model/AppDistribution.swift \
  HDiaryLibrary/Tests/HDiaryIAPTests/HDiaryIAPTests.swift
git commit -m "Add TestFlight distribution classifier"
```

---

### 任务 2：独立功能权限策略和 SwiftUI 环境注入

**文件：**

- 新建：`HDiaryLibrary/Sources/HDiaryIAP/Model/RecordFeatureAccess.swift`
- 修改：`HDiaryLibrary/Tests/HDiaryIAPTests/HDiaryIAPTests.swift:8-67`
- 修改：`HDiaryLibrary/Sources/HDiaryIAP/View/RecordSubscriptionModifier.swift:15-72`

**接口：**

- 使用：任务 1 的 `AppDistribution.current` 和 `AppDistribution.testFlight`，现有 `RecordSubscriptionStatus`。
- 提供：`RecordFeatureAccessPolicy.allowsAccess(for:distribution:) -> Bool` 和公开 SwiftUI 环境值 `EnvironmentValues.recordFeatureAccessAllowed: Bool`。

- [ ] **步骤 1：添加功能权限策略失败测试**

在 `HDiaryIAPTests` 类结束前加入：

```swift
    func testTestFlightAllowsAccessWithoutSubscription() {
      XCTAssertTrue(
        RecordFeatureAccessPolicy.allowsAccess(
          for: .notSubscribed,
          distribution: .testFlight
        )
      )
    }

    func testOtherDistributionDeniesAccessWithoutSubscription() {
      XCTAssertFalse(
        RecordFeatureAccessPolicy.allowsAccess(
          for: .notSubscribed,
          distribution: .other
        )
      )
    }

    func testMonthlySubscriptionAllowsAccessInOtherDistribution() {
      XCTAssertTrue(
        RecordFeatureAccessPolicy.allowsAccess(
          for: .monthly(expirationDate: .distantFuture),
          distribution: .other
        )
      )
    }

    func testAnnualSubscriptionAllowsAccessInOtherDistribution() {
      XCTAssertTrue(
        RecordFeatureAccessPolicy.allowsAccess(
          for: .annually(expirationDate: .distantFuture),
          distribution: .other
        )
      )
    }

    func testFeatureAccessEnvironmentDefaultsToDenied() {
      XCTAssertFalse(EnvironmentValues().recordFeatureAccessAllowed)
    }
```

并在文件顶部增加：

```swift
  import SwiftUI
```

- [ ] **步骤 2：运行测试并确认按预期失败**

运行：

```bash
xcodebuildmcp simulator test \
  --project-path /Users/tigerguo/.codex/worktrees/d1bb/HHappyDocs/HDiary.xcodeproj \
  --scheme HDiary \
  --simulator-id A044BA15-7770-48E6-8E28-E2123A772ACD \
  --extra-args "-only-testing:HDiaryIAPTests/HDiaryIAPTests"
```

预期：失败，编译器报告找不到 `RecordFeatureAccessPolicy` 或 `recordFeatureAccessAllowed`。

- [ ] **步骤 3：添加最小功能权限实现**

新建 `RecordFeatureAccess.swift`：

```swift
import SwiftUI

enum RecordFeatureAccessPolicy {
  static func allowsAccess(
    for status: RecordSubscriptionStatus,
    distribution: AppDistribution
  ) -> Bool {
    if distribution == .testFlight {
      return true
    }

    switch status {
    case .notSubscribed:
      return false
    case .monthly, .annually:
      return true
    }
  }
}

public extension EnvironmentValues {
  enum RecordFeatureAccessAllowedEnvironmentKey: EnvironmentKey {
    public static let defaultValue = false
  }

  var recordFeatureAccessAllowed: Bool {
    get { self[RecordFeatureAccessAllowedEnvironmentKey.self] }
    set { self[RecordFeatureAccessAllowedEnvironmentKey.self] = newValue }
  }
}
```

- [ ] **步骤 4：把派生权限注入订阅环境**

在 `RecordSubscriptionStatusModifier` 的 `state` 后加入：

```swift
    private let appDistribution = AppDistribution.current

    private var subscriptionStatus: RecordSubscriptionStatus {
      state.value ?? .notSubscribed
    }

    private var recordFeatureAccessAllowed: Bool {
      RecordFeatureAccessPolicy.allowsAccess(
        for: subscriptionStatus,
        distribution: appDistribution
      )
    }
```

把现有环境注入：

```swift
        .environment(\.recordSubscriptionStatus, state.value ?? .notSubscribed)
        .environment(\.recordSubscriptionStatusIsLoading, isLoading)
```

替换为：

```swift
        .environment(\.recordSubscriptionStatus, subscriptionStatus)
        .environment(\.recordFeatureAccessAllowed, recordFeatureAccessAllowed)
        .environment(\.recordSubscriptionStatusIsLoading, isLoading)
```

在现有 `.task` 的 `readDataFromDisk()` 前记录非敏感分发信息：

```swift
          Log.iap.info(
            "App distribution: \(String(describing: appDistribution), privacy: .public)"
          )
```

不要修改写入 `userPreferences.recordSubscriptionStatusData` 的任何代码。

- [ ] **步骤 5：重新运行 IAP 测试**

运行与步骤 2 相同的 XcodeBuildMCP 命令。

预期：`HDiaryIAPTests/HDiaryIAPTests` 中 10 个测试全部通过，且 `RecordSubscriptionModifier.swift` 编译成功。

- [ ] **步骤 6：提交独立功能权限**

```bash
git add \
  HDiaryLibrary/Sources/HDiaryIAP/Model/RecordFeatureAccess.swift \
  HDiaryLibrary/Sources/HDiaryIAP/View/RecordSubscriptionModifier.swift \
  HDiaryLibrary/Tests/HDiaryIAPTests/HDiaryIAPTests.swift
git commit -m "Add TestFlight feature access policy"
```

---

### 任务 3：新增时刻门禁改用功能权限

**文件：**

- 新建：`HDiaryLibrary/Tests/HDiaryAppFeatureTests/AddMomentAccessTests.swift`
- 修改：`HDiaryLibrary/Sources/HDiaryAppFeature/Moments/AddMoment/AddMomentNavigationView.swift:15-112`

**接口：**

- 使用：任务 2 的公开环境值 `EnvironmentValues.recordFeatureAccessAllowed`。
- 提供：可测试的 `AddMomentPresentation.resolve(hasFeatureAccess:hasShownPromotion:currentMomentCount:freeRecordNumber:) -> AddMomentPresentation`，并让 `AddMomentNavigationView` 使用该结果。

- [ ] **步骤 1：添加页面路由失败测试**

新建 `AddMomentAccessTests.swift`：

```swift
#if os(iOS)

  @testable import HDiaryAppFeature
  import XCTest

  final class AddMomentAccessTests: XCTestCase {
    func testGrantedAccessSkipsFirstUsePromotion() {
      let result = AddMomentPresentation.resolve(
        hasFeatureAccess: true,
        hasShownPromotion: false,
        currentMomentCount: 0,
        freeRecordNumber: 3
      )

      XCTAssertEqual(result, .presentAddMomentView)
    }

    func testGrantedAccessSkipsPaywallAboveFreeLimit() {
      let result = AddMomentPresentation.resolve(
        hasFeatureAccess: true,
        hasShownPromotion: true,
        currentMomentCount: 4,
        freeRecordNumber: 3
      )

      XCTAssertEqual(result, .presentAddMomentView)
    }

    func testDeniedAccessShowsFirstUsePromotion() {
      let result = AddMomentPresentation.resolve(
        hasFeatureAccess: false,
        hasShownPromotion: false,
        currentMomentCount: 0,
        freeRecordNumber: 3
      )

      XCTAssertEqual(result, .presentRecordSubscriptionPromotionView)
    }

    func testDeniedAccessShowsPaywallAtFreeLimitAfterPromotion() {
      let result = AddMomentPresentation.resolve(
        hasFeatureAccess: false,
        hasShownPromotion: true,
        currentMomentCount: 3,
        freeRecordNumber: 3
      )

      XCTAssertEqual(result, .presentRecordSubscriptionView)
    }

    func testDeniedAccessAllowsUseBelowFreeLimitAfterPromotion() {
      let result = AddMomentPresentation.resolve(
        hasFeatureAccess: false,
        hasShownPromotion: true,
        currentMomentCount: 2,
        freeRecordNumber: 3
      )

      XCTAssertEqual(result, .presentAddMomentView)
    }
  }

#endif
```

- [ ] **步骤 2：运行页面路由测试并确认按预期失败**

运行：

```bash
xcodebuildmcp simulator test \
  --project-path /Users/tigerguo/.codex/worktrees/d1bb/HHappyDocs/HDiary.xcodeproj \
  --scheme HDiary \
  --simulator-id A044BA15-7770-48E6-8E28-E2123A772ACD \
  --extra-args "-only-testing:HDiaryAppFeatureTests/AddMomentAccessTests"
```

预期：失败，编译器报告找不到 `AddMomentPresentation`。

- [ ] **步骤 3：提取并实现纯页面路由决策**

把文件顶部的私有 `PresentState` 改为：

```swift
enum AddMomentPresentation: Identifiable, Equatable, Hashable {
  case presentRecordSubscriptionView
  case presentRecordSubscriptionPromotionView
  case presentAddMomentView

  var id: Self { self }

  static func resolve(
    hasFeatureAccess: Bool,
    hasShownPromotion: Bool,
    currentMomentCount: Int,
    freeRecordNumber: Int
  ) -> Self {
    if hasFeatureAccess {
      return .presentAddMomentView
    }

    if !hasShownPromotion {
      return .presentRecordSubscriptionPromotionView
    }

    if currentMomentCount >= freeRecordNumber {
      return .presentRecordSubscriptionView
    }

    return .presentAddMomentView
  }
}
```

把：

```swift
  @Environment(\.recordSubscriptionStatus) private var recordSubscriptionStatus
```

替换为：

```swift
  @Environment(\.recordFeatureAccessAllowed) private var recordFeatureAccessAllowed
```

并把：

```swift
  @State private var presentState: PresentState?
```

替换为：

```swift
  @State private var presentState: AddMomentPresentation?
```

- [ ] **步骤 4：让 `onInit()` 使用纯决策结果**

保留现有 `#if DEBUG` 绕过逻辑。把其后的订阅状态分支整体替换为：

```swift
    let nextState = AddMomentPresentation.resolve(
      hasFeatureAccess: recordFeatureAccessAllowed,
      hasShownPromotion: userPreferences.hasShownRecordPromotionView,
      currentMomentCount: currentMomentCount,
      freeRecordNumber: AppConstants.IAP.freeRecordNumber
    )

    presentState = nextState

    switch nextState {
    case .presentRecordSubscriptionView:
      Log.iap.info("Show need subscribe view")
    case .presentRecordSubscriptionPromotionView:
      Log.iap.info("Show RecordSubscriptionPromotionView")
    case .presentAddMomentView:
      Log.iap.log("add moment")
    }
```

不要修改 `RecordSubscriptionBuyCell`、`RecordSubscriptionView` 或 `RecordSubscriptionPromotionView`。

- [ ] **步骤 5：重新运行页面路由和 IAP 测试**

先运行与步骤 2 相同的页面路由测试命令。

预期：`AddMomentAccessTests` 中 5 个测试全部通过。

再运行：

```bash
xcodebuildmcp simulator test \
  --project-path /Users/tigerguo/.codex/worktrees/d1bb/HHappyDocs/HDiary.xcodeproj \
  --scheme HDiary \
  --simulator-id A044BA15-7770-48E6-8E28-E2123A772ACD \
  --extra-args "-only-testing:HDiaryIAPTests/HDiaryIAPTests"
```

预期：10 个 IAP 测试继续全部通过。

- [ ] **步骤 6：提交页面门禁接入**

```bash
git add \
  HDiaryLibrary/Sources/HDiaryAppFeature/Moments/AddMoment/AddMomentNavigationView.swift \
  HDiaryLibrary/Tests/HDiaryAppFeatureTests/AddMomentAccessTests.swift
git commit -m "Use feature access for moment gating"
```

---

### 任务 4：完整验证与范围检查

**文件：**

- 验证：任务 1 至任务 3 的全部改动。
- 不新增或修改产品代码。

**接口：**

- 使用：任务 1 至任务 3 的所有接口。
- 提供：通过的相关测试、完整 scheme 测试以及干净的差异检查。

- [ ] **步骤 1：运行两个目标测试套件**

运行：

```bash
xcodebuildmcp simulator test \
  --project-path /Users/tigerguo/.codex/worktrees/d1bb/HHappyDocs/HDiary.xcodeproj \
  --scheme HDiary \
  --simulator-id A044BA15-7770-48E6-8E28-E2123A772ACD \
  --extra-args "-only-testing:HDiaryIAPTests" \
  --extra-args "-only-testing:HDiaryAppFeatureTests"
```

预期：`HDiaryIAPTests` 和 `HDiaryAppFeatureTests` 全部通过，无编译错误和测试失败。

- [ ] **步骤 2：运行完整 HDiary scheme 测试**

运行：

```bash
xcodebuildmcp simulator test \
  --project-path /Users/tigerguo/.codex/worktrees/d1bb/HHappyDocs/HDiary.xcodeproj \
  --scheme HDiary \
  --simulator-id A044BA15-7770-48E6-8E28-E2123A772ACD
```

预期：完整 `HDiary` scheme 测试通过。

- [ ] **步骤 3：检查格式、范围和持久化边界**

运行：

```bash
git diff --check HEAD~3..HEAD
git diff --stat HEAD~3..HEAD
git diff HEAD~3..HEAD -- \
  HDiaryLibrary/Sources/HDiaryIAP/View/RecordSubscriptionBuyCell.swift \
  HDiaryLibrary/Sources/HDiaryIAP/View/RecordSubscriptionView.swift \
  HDiaryLibrary/Sources/HDiaryAppFeature/IAP/RecordSubscriptionPromotionView.swift
rg -n "recordSubscriptionStatusData" \
  HDiaryLibrary/Sources/HDiaryIAP \
  HDiaryLibrary/Sources/HDiaryAppFeature
git status --short --branch
```

预期：

- `git diff --check` 无输出。
- 差异统计只包含计划列出的源文件和测试文件。
- 三个购买相关界面的差异为空。
- `recordSubscriptionStatusData` 仍只在现有真实订阅缓存流程中读写，新文件中没有该字符串。
- 工作区没有未提交的产品代码或测试改动。

- [ ] **步骤 4：记录验证证据**

在最终交付中报告：

- XcodeBuildMCP 使用的绝对工程路径、scheme 和模拟器。
- 两个目标测试套件的通过数量。
- 完整 scheme 测试结果。
- 三个实现提交的提交哈希。
- TestFlight 权限未持久化、购买界面未修改的差异检查结果。
