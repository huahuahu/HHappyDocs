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
