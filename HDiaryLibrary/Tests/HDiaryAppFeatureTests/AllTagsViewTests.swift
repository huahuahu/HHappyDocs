import XCTest
@testable import HDiaryAppFeature

final class AllTagsViewTests: XCTestCase {
  func testEmptyTagsDoNotShowTotalTagCount() {
    let state = AllTagsViewState(totalTagCount: 0)

    XCTAssertFalse(state.shouldShowTotalTagCount)
  }

  func testNonEmptyTagsShowTotalTagCount() {
    let state = AllTagsViewState(totalTagCount: 1)

    XCTAssertTrue(state.shouldShowTotalTagCount)
  }
}
