#if os(iOS)

@testable import HDiaryAppFeature
import SwiftUI
import XCTest

@MainActor
final class LibraryEntryLayoutPolicyTests: XCTestCase {
  func testStandardDynamicTypeSizesAllowResponsiveMeasurement() {
    for size in [DynamicTypeSize.xSmall, .large, .xxxLarge] {
      XCTAssertFalse(
        LibraryEntryLayoutPolicy.forcesSingleColumn(for: size),
        "Expected \(size) to let ViewThatFits measure the three-column candidate"
      )
    }
  }

  func testAccessibilityDynamicTypeSizesForceSingleColumn() {
    for size in [DynamicTypeSize.accessibility1, .accessibility3, .accessibility5] {
      XCTAssertTrue(
        LibraryEntryLayoutPolicy.forcesSingleColumn(for: size),
        "Expected \(size) to bypass the three-column candidate"
      )
    }
  }
}

#endif
