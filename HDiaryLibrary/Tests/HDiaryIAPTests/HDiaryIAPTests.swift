#if os(iOS)

  @testable import HDiaryIAP
  import SwiftUI
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
