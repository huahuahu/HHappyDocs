#if DEBUG && os(iOS)
  @testable import HDiaryAppFeature
  import SnapshotTesting
  import SwiftUI
  import Testing

  @Suite(.serialized)
  @MainActor
  struct MomentDetailSnapshotTests {
    @Test("乐事详情整页", arguments: MomentDetailPreviewScenario.allCases)
    func momentDetail(_ scenario: MomentDetailPreviewScenario) throws {
      try #require(String(localized: DiaryStringKey.momentDetailViewNavigationTitle) == "乐事详情", "快照必须加载应用的中文资源。")
      let fixture = try #require(ListSnapshotFixtures.shared.get().momentDetails[scenario])
      let contentSize: UIContentSizeCategory = switch scenario {
      case .accessibility:
        .accessibilityExtraLarge
      case .compactAccessibility:
        .accessibilityLarge
      default:
        .large
      }
      assertSnapshot(
        of: MomentDetailPreview(fixture: fixture),
        as: try ListSnapshotConfiguration.image(
          style: scenario == .dark ? .dark : .light,
          contentSize: contentSize,
          width: scenario == .compactAccessibility ? 320 : nil
        ),
        named: try ListSnapshotConfiguration.name(scenario.rawValue), record: ListSnapshotConfiguration.record,
        testName: "moment-detail"
      )
    }
  }
#endif
