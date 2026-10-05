#if DEBUG && os(iOS)
  @testable import HDiaryAppFeature
  import SnapshotTesting
  import SwiftUI
  import Testing

  @Suite(.serialized)
  @MainActor
  struct TagDetailSnapshotTests {
    @Test("标签详情页面", arguments: TagDetailPreviewScenario.allCases)
    func tagDetail(_ scenario: TagDetailPreviewScenario) throws {
      try #require(String(localized: DiaryStringKey.tagEntryLabel) == "标签", "快照必须加载应用的中文资源。")
      let fixture = try #require(ListSnapshotFixtures.shared.get().tagDetails[scenario])
      let contentSize: UIContentSizeCategory = switch scenario {
      case .accessibility, .compactAccessibility:
        .accessibilityLarge
      case .accessibilityMax:
        .accessibilityExtraExtraExtraLarge
      default:
        .large
      }
      assertSnapshot(
        of: TagDetailPreview(fixture: fixture),
        as: ListSnapshotConfiguration.image(
          style: scenario == .dark ? .dark : .light,
          contentSize: contentSize,
          width: scenario == .compactAccessibility ? 320 : 402
        ),
        named: scenario.rawValue, record: ListSnapshotConfiguration.record,
        testName: "tag-detail"
      )
    }
  }
#endif
