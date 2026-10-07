#if DEBUG && os(iOS)
  @testable import HDiaryAppFeature
  import SnapshotTesting
  import SwiftUI
  import XCTest

  /// Render the actual list directly, without launching or driving the App.
  @MainActor
  final class MomentListSnapshotTests: XCTestCase {
    func testGroupedList() throws {
      try snapshot(.grouped)
    }

    func testExpandedList() throws {
      try snapshot(.expanded)
    }

    func testEmptyList() throws {
      try snapshot(.empty)
    }

    private func snapshot(_ scenario: MomentListPreviewScenario) throws {
      XCTAssertEqual(String(localized: DiaryStringKey.happyListNavigationTitle), "乐事", "快照必须加载应用的中文资源。")
      let fixture = try XCTUnwrap(ListSnapshotFixtures.shared.get().moments[scenario])
      assertSnapshot(
        of: MomentListPreview(fixture: fixture).tint(.orange),
        as: try ListSnapshotConfiguration.image(),
        named: try ListSnapshotConfiguration.name(scenario.rawValue), record: ListSnapshotConfiguration.record, testName: "moment-list"
      )
    }
  }
#endif
