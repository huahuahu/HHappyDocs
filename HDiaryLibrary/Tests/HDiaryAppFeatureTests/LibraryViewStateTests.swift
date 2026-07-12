#if os(iOS)

@testable import HDiaryAppFeature
import XCTest

@MainActor
final class LibraryViewStateTests: XCTestCase {
  func testTagSummaryUsesTagCount() {
    let state = LibraryViewState(tagCount: 3, participantCount: 7)

    XCTAssertEqual(
      state.summary(for: .tag),
      DiaryStringKey.tagEntrySummary(count: 3)
    )
  }

  func testParticipantSummaryUsesParticipantCount() {
    let state = LibraryViewState(tagCount: 3, participantCount: 7)

    XCTAssertEqual(
      state.summary(for: .participant),
      DiaryStringKey.participantEntrySummary(count: 7)
    )
    XCTAssertEqual(
      String(localized: state.summary(for: .participant)),
      "7"
    )
  }

  func testChartSummaryDoesNotDependOnCounts() {
    let emptyState = LibraryViewState(tagCount: 0, participantCount: 0)
    let populatedState = LibraryViewState(tagCount: 12, participantCount: 9)

    XCTAssertEqual(emptyState.summary(for: .chart), DiaryStringKey.chartEntrySummary)
    XCTAssertEqual(populatedState.summary(for: .chart), DiaryStringKey.chartEntrySummary)
  }

  func testZeroCountsRemainVisibleSummaries() {
    let state = LibraryViewState(tagCount: 0, participantCount: 0)

    XCTAssertEqual(
      state.summary(for: .tag),
      DiaryStringKey.tagEntrySummary(count: 0)
    )
    XCTAssertEqual(
      state.summary(for: .participant),
      DiaryStringKey.participantEntrySummary(count: 0)
    )
    XCTAssertEqual(
      String(localized: state.summary(for: .participant)),
      "0"
    )
  }
}

#endif
