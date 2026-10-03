#if DEBUG && os(iOS)
  @testable import HDiaryAppFeature
  import SnapshotTesting
  import SwiftUI
  import XCTest

  /// Render the actual list directly, without launching or driving the App.
  @MainActor
  final class MomentListSnapshotTests: XCTestCase {
    // Seed all independent stores before attaching any SwiftData query to a window.
    // Saving a new store while a detached TabView query is alive can crash SwiftData.
    private static let fixtures = Result {
      try Dictionary(uniqueKeysWithValues: MomentListPreviewScenario.allCases.map {
        ($0, try MomentListPreviewFixture(scenario: $0))
      })
    }

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
      let fixture = try XCTUnwrap(Self.fixtures.get()[scenario])
      let traits = UITraitCollection {
        $0.userInterfaceStyle = .light
        $0.displayScale = 3
        $0.preferredContentSizeCategory = .large
      }
      let config = ViewImageConfig(
        safeArea: UIEdgeInsets(top: 62, left: 0, bottom: 34, right: 0),
        size: CGSize(width: 402, height: 874), traits: traits
      )
      let record: SnapshotTestingConfiguration.Record =
        ProcessInfo.processInfo.environment["HDIARY_RECORD_SNAPSHOTS"] == "1" ? .all : .never
      assertSnapshot(
        of: MomentListPreview(fixture: fixture).tint(.orange),
        // System glass shadows vary by 1–2 RGB levels between identical runs.
        // Check every pixel, allowing only a small perceptual color difference.
        as: .image(
          drawHierarchyInKeyWindow: true, precision: 1, perceptualPrecision: 0.99,
          layout: .device(config: config), traits: traits
        ),
        named: scenario.rawValue, record: record, testName: "moment-list"
      )
    }
  }
#endif
