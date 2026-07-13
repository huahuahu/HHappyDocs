#if os(iOS)

@testable import HDiaryAppFeature
import SwiftUI
import XCTest

@MainActor
final class LibraryEntryRenderingTests: XCTestCase {
  func testHorizontalParticipantCardUsesAvailableTextWidthAtAccessibilityXXXL() throws {
    let renderer = ImageRenderer(
      content: LibraryEntryCard(
        entry: .participant,
        summary: .count(10),
        contentAxis: .horizontal
      )
      .environment(\.locale, Locale(identifier: "en"))
      .environment(\.dynamicTypeSize, .accessibility5)
      .frame(width: 312)
    )
    renderer.proposedSize = ProposedViewSize(width: 312, height: nil)

    let image = try XCTUnwrap(
      renderer.uiImage,
      "Expected the horizontal participant card to render"
    )
    XCTAssertLessThan(
      image.size.height,
      1_000,
      "Expected readable horizontal text layout; actual height: \(image.size.height)pt"
    )
  }

  func testCardRendersForVerticalAndHorizontalContentAxes() {
    let scenarios: [(axis: Axis, width: CGFloat, height: CGFloat)] = [
      (.vertical, 104, 180),
      (.horizontal, 320, 110),
    ]

    for scenario in scenarios {
      let renderer = ImageRenderer(
        content: LibraryEntryCard(
          entry: .tag,
          summary: .count(3),
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

  func testDashboardRendersForNarrowWideAndAccessibilityProposals() {
    let scenarios: [(width: CGFloat, height: CGFloat, size: DynamicTypeSize)] = [
      (288, 600, .large),
      (360, 300, .large),
      (688, 800, .accessibility3),
    ]

    for scenario in scenarios {
      let renderer = ImageRenderer(
        content: LibraryEntryDashboard(
          viewState: LibraryViewState(tagCount: 3, participantCount: 7)
        )
        .environment(\.dynamicTypeSize, scenario.size)
        .frame(width: scenario.width)
      )
      renderer.proposedSize = ProposedViewSize(
        width: scenario.width,
        height: scenario.height
      )

      XCTAssertNotNil(
        renderer.uiImage,
        "Expected the dashboard to render at width \(scenario.width), size \(scenario.size)"
      )
    }
  }
}

#endif
