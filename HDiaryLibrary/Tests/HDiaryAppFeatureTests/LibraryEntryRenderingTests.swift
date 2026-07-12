#if os(iOS)

@testable import HDiaryAppFeature
import SwiftUI
import XCTest

@MainActor
final class LibraryEntryRenderingTests: XCTestCase {
  func testCardRendersForVerticalAndHorizontalContentAxes() {
    let scenarios: [(axis: Axis, width: CGFloat, height: CGFloat)] = [
      (.vertical, 104, 180),
      (.horizontal, 320, 110),
    ]

    for scenario in scenarios {
      let renderer = ImageRenderer(
        content: LibraryEntryCard(
          entry: .tag,
          summary: DiaryStringKey.tagEntrySummary(count: 3),
          contentAxis: scenario.axis
        )
        .frame(width: scenario.width)
      )
      renderer.proposedSize = ProposedViewSize(
        width: scenario.width,
        height: scenario.height
      )

      XCTAssertNotNil(
        renderer.uiImage,
        "Expected the card to render for \(scenario.axis) content"
      )
    }
  }
}

#endif
