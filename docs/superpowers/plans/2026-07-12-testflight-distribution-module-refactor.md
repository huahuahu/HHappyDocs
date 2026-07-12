# TestFlight 分发判定模块迁移实现计划

> **面向执行代理：** REQUIRED SUB-SKILL: 使用 `subagent-driven-development`（推荐）或 `executing-plans` 逐项执行本计划。所有步骤使用复选框（`- [ ]`）跟踪。

**目标：** 将可复用的 TestFlight 分发判定从 `HDiaryIAP` 迁移到 `HDiaryConstants`，供主 App 进程内的多个模块使用，同时保持现有 IAP 功能权限行为不变。

**架构：** `HDiaryConstants` 提供公开的 `AppDistribution` 类型和 `.current` 运行时入口，纯 `classify(...)` 判定保持模块内部可见并由 `HDiaryConstantsTests` 覆盖。`HDiaryIAP` 继续拥有 `RecordFeatureAccessPolicy`，通过既有依赖消费共享分发信息，不把订阅策略下沉到公共模块。

**技术栈：** Swift 6、Foundation、Swift Package、XCTest、XcodeBuildMCP。

## 全局约束

- iOS 最低版本保持 `17.0`，Swift Package 平台保持 iOS 17、macOS 14。
- 不增加新的 Swift Package target、product 或第三方依赖。
- `AppDistribution`、`.testFlight`、`.other` 和 `.current` 对其他模块公开；`classify(receiptLastPathComponent:hasEmbeddedMobileProvision:isSimulator:)` 保持 `HDiaryConstants` 模块内部可见。
- 只有真机、收据名为 `sandboxReceipt`、并且不存在 `embedded.mobileprovision` 时返回 `.testFlight`；其他组合全部保守返回 `.other`。
- `AppDistribution.current` 只承诺主 App 进程行为；不为 Widget 或其他 App Extension 增加共享或判定逻辑。
- `RecordFeatureAccessPolicy`、SwiftUI 环境值和订阅状态持久化继续留在 `HDiaryIAP`。
- `recordSubscriptionStatus` 和 `recordSubscriptionStatusData` 必须继续只表示真实 StoreKit 状态；TestFlight 权限不能写入 UserDefaults 或其他持久化存储。
- `RecordSubscriptionBuyCell`、`RecordSubscriptionView`、`RecordSubscriptionPromotionView`、购买、恢复、续订、过期和升级流程保持不变。
- 所有构建和测试使用 XcodeBuildMCP，不直接调用 `xcodebuild`、`xcrun` 或 `simctl`。
- XcodeBuildMCP 工程固定为 `/Users/tigerguo/.codex/worktrees/d1bb/HHappyDocs/HDiary.xcodeproj`，scheme 固定为 `HDiary`，模拟器 ID 固定为 `A044BA15-7770-48E6-8E28-E2123A772ACD`。
- 当前 XcodeBuildMCP CLI `2.6.2` 不提供 `session_show_defaults` 或 `session_set_defaults`；首次测试前核对 `.xcodebuildmcp/config.yaml`，并在每条测试命令中显式传入绝对工程路径、scheme 和模拟器 ID。

## 文件结构

- 新建 `HDiaryLibrary/Sources/HDiaryConstants/AppEnvironment/AppDistribution.swift`：提供主 App 进程可复用的分发来源类型和运行时判定。
- 删除 `HDiaryLibrary/Sources/HDiaryIAP/Model/AppDistribution.swift`：移除 IAP 内部的旧文件，避免重复定义。
- 修改 `HDiaryLibrary/Sources/HDiaryIAP/Model/RecordFeatureAccess.swift`：显式导入 `HDiaryConstants`，策略本身保持不变。
- 修改 `HDiaryLibrary/Tests/HDiaryConstantsTests/HDiaryConstantsTests.swift`：用五个分发矩阵测试替换无业务意义的占位测试。
- 修改 `HDiaryLibrary/Tests/HDiaryIAPTests/HDiaryIAPTests.swift`：删除已迁移的五个分发测试，只保留五个 IAP 权限策略测试，并显式导入 `HDiaryConstants`。
- 修改 `HDiaryLibrary/Package.swift`：让 `HDiaryIAPTests` 直接依赖 `HDiaryConstants`，测试跨模块公开 API。

---

### Task 1：迁移共享分发判定并保持 IAP 行为

**文件：**

- 新建：`HDiaryLibrary/Sources/HDiaryConstants/AppEnvironment/AppDistribution.swift`
- 删除：`HDiaryLibrary/Sources/HDiaryIAP/Model/AppDistribution.swift`
- 修改：`HDiaryLibrary/Sources/HDiaryIAP/Model/RecordFeatureAccess.swift:1-6`
- 修改：`HDiaryLibrary/Tests/HDiaryConstantsTests/HDiaryConstantsTests.swift:1-17`
- 修改：`HDiaryLibrary/Tests/HDiaryIAPTests/HDiaryIAPTests.swift:1-101`
- 修改：`HDiaryLibrary/Package.swift:127-130`

**接口：**

- 使用：`Bundle.main.appStoreReceiptURL`、`Bundle.main.url(forResource:withExtension:)`、`targetEnvironment(simulator)`、现有 `RecordFeatureAccessPolicy`。
- 提供：公开 `AppDistribution.testFlight`、`AppDistribution.other`、`AppDistribution.current`；模块内部 `AppDistribution.classify(receiptLastPathComponent:hasEmbeddedMobileProvision:isSimulator:) -> AppDistribution`。

- [ ] **步骤 1：确认 XcodeBuildMCP 配置和命令能力**

运行：

```bash
xcodebuildmcp --version
xcodebuildmcp tools | rg "session|defaults" || true
sed -n '1,120p' .xcodebuildmcp/config.yaml
```

预期：CLI 版本为 `2.6.2`，工具列表中没有 `session_show_defaults` 或 `session_set_defaults`；配置文件的 `sessionDefaults` 包含 `projectPath: HDiary.xcodeproj`、`scheme: HDiary` 和 `simulatorId: A044BA15-7770-48E6-8E28-E2123A772ACD`。后续测试仍显式传入绝对参数。

- [ ] **步骤 2：把分发矩阵测试移入 Constants 测试目标**

用以下内容替换 `HDiaryConstantsTests.swift`：

```swift
#if os(iOS)

  @testable import HDiaryConstants
  import XCTest

  final class HDiaryConstantsTests: XCTestCase {
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

- [ ] **步骤 3：运行 Constants 测试并确认按预期失败**

运行：

```bash
xcodebuildmcp simulator test \
  --project-path /Users/tigerguo/.codex/worktrees/d1bb/HHappyDocs/HDiary.xcodeproj \
  --scheme HDiary \
  --simulator-id A044BA15-7770-48E6-8E28-E2123A772ACD \
  --extra-args "-only-testing:HDiaryConstantsTests/HDiaryConstantsTests"
```

预期：编译失败，`HDiaryConstantsTests.swift` 报告找不到 `AppDistribution`。如果失败来自工程或模拟器配置，先修正执行环境，直到失败原因只剩共享类型尚未迁移。

- [ ] **步骤 4：把判定器移动到 HDiaryConstants 并公开跨模块接口**

新建 `HDiaryLibrary/Sources/HDiaryConstants/AppEnvironment/AppDistribution.swift`：

```swift
import Foundation

public enum AppDistribution: Equatable, Sendable {
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

  public static var current: Self {
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

删除旧文件：

```text
HDiaryLibrary/Sources/HDiaryIAP/Model/AppDistribution.swift
```

在 `RecordFeatureAccess.swift` 顶部把：

```swift
import SwiftUI
```

替换为：

```swift
import HDiaryConstants
import SwiftUI
```

`RecordFeatureAccessPolicy` 和 `recordFeatureAccessAllowed` 的实现保持不变。

- [ ] **步骤 5：让 IAP 测试显式消费 Constants 的公开类型**

在 `HDiaryLibrary/Package.swift` 的 `HDiaryIAPTests` 目标中，把依赖替换为：

```swift
    .testTarget(
      name: "HDiaryIAPTests",
      dependencies: [
        "HDiaryConstants",
        "HDiaryIAP",
      ],
      swiftSettings: packageSwiftSettings
    ),
```

用以下内容替换 `HDiaryIAPTests.swift`，删除已迁移的分发矩阵测试：

```swift
#if os(iOS)

  @testable import HDiaryIAP
  import HDiaryConstants
  import SwiftUI
  import XCTest

  final class HDiaryIAPTests: XCTestCase {
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
  }

#endif
```

- [ ] **步骤 6：运行迁移后的 Constants 与 IAP 测试**

运行：

```bash
xcodebuildmcp simulator test \
  --project-path /Users/tigerguo/.codex/worktrees/d1bb/HHappyDocs/HDiary.xcodeproj \
  --scheme HDiary \
  --simulator-id A044BA15-7770-48E6-8E28-E2123A772ACD \
  --extra-args "-only-testing:HDiaryConstantsTests/HDiaryConstantsTests" \
  --extra-args "-only-testing:HDiaryIAPTests/HDiaryIAPTests"
```

预期：`HDiaryConstantsTests` 5 个测试和 `HDiaryIAPTests` 5 个测试全部通过，共 10 个通过、0 个失败。

- [ ] **步骤 7：运行完整默认测试计划**

运行：

```bash
xcodebuildmcp simulator test \
  --project-path /Users/tigerguo/.codex/worktrees/d1bb/HHappyDocs/HDiary.xcodeproj \
  --scheme HDiary \
  --simulator-id A044BA15-7770-48E6-8E28-E2123A772ACD
```

预期：默认 `HDiary/HDiary.xctestplan` 中 37 个测试全部通过、0 个失败。数量由迁移前 38 个减去被替换的 1 个无业务意义 Constants 占位测试得出；默认计划仍不包含既有 `HDiaryUITests` 的 3 个 UI 测试。

- [ ] **步骤 8：检查模块边界、持久化边界和差异范围**

运行：

```bash
git diff --check
rg -n "enum AppDistribution|static func classify|static var current" \
  HDiaryLibrary/Sources/HDiaryConstants \
  HDiaryLibrary/Sources/HDiaryIAP
rg -n "recordSubscriptionStatusData" \
  HDiaryLibrary/Sources/HDiaryIAP \
  HDiaryLibrary/Sources/HDiaryAppFeature
git diff -- \
  HDiaryLibrary/Sources/HDiaryIAP/View/RecordSubscriptionBuyCell.swift \
  HDiaryLibrary/Sources/HDiaryIAP/View/RecordSubscriptionView.swift \
  HDiaryLibrary/Sources/HDiaryAppFeature/IAP/RecordSubscriptionPromotionView.swift
git status --short
```

预期：

- `git diff --check` 无输出。
- `AppDistribution` 的唯一定义、`classify` 和 `.current` 均位于 `HDiaryConstants/AppEnvironment/AppDistribution.swift`。
- `recordSubscriptionStatusData` 仍只在既有真实订阅缓存流程中读写；新文件中没有该字符串。
- 三个购买相关界面的差异为空。
- 工作区只包含本任务列出的六个文件变化，其中旧 `AppDistribution.swift` 删除、新路径文件新增。

- [ ] **步骤 9：提交模块迁移**

```bash
git add \
  HDiaryLibrary/Package.swift \
  HDiaryLibrary/Sources/HDiaryConstants/AppEnvironment/AppDistribution.swift \
  HDiaryLibrary/Sources/HDiaryIAP/Model/AppDistribution.swift \
  HDiaryLibrary/Sources/HDiaryIAP/Model/RecordFeatureAccess.swift \
  HDiaryLibrary/Tests/HDiaryConstantsTests/HDiaryConstantsTests.swift \
  HDiaryLibrary/Tests/HDiaryIAPTests/HDiaryIAPTests.swift
git commit -m "Move app distribution to shared constants"
```

