#if os(iOS)

  @testable import HDiaryAppFeature
  import XCTest

  @MainActor
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
