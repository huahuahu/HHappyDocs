import XCTest
@testable import HDiary

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
