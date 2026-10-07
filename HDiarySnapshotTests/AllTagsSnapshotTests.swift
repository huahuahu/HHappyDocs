#if DEBUG && os(iOS)
  @testable import HDiaryAppFeature
  import SnapshotTesting
  import SwiftUI
  import Testing

  @Suite(.serialized)
  @MainActor
  struct AllTagsSnapshotTests {
    @Test("全部标签页面", arguments: AllTagsPreviewScenario.allCases)
    func allTags(_ scenario: AllTagsPreviewScenario) throws {
      try #require(String(localized: DiaryStringKey.tagEntryLabel) == "标签", "快照必须加载应用的中文资源。")
      let fixture = try #require(ListSnapshotFixtures.shared.get().tags[scenario])
      assertSnapshot(
        of: AllTagsPreview(fixture: fixture),
        as: try ListSnapshotConfiguration.image(
          style: scenario == .dark ? .dark : .light,
          contentSize: scenario == .accessibility ? .accessibilityLarge : .large
        ),
        named: try ListSnapshotConfiguration.name(scenario.rawValue), record: ListSnapshotConfiguration.record,
        testName: "all-tags"
      )
    }
  }
#endif
