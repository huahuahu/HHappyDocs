#if DEBUG && os(iOS)
  @testable import HDiaryAppFeature
  import SnapshotTesting
  import SwiftUI
  import Testing

  @Suite(.serialized)
  @MainActor
  struct ParticipantDetailSnapshotTests {
    @Test("参与者详情整页", arguments: ParticipantDetailPreviewScenario.allCases)
    func participantDetail(_ scenario: ParticipantDetailPreviewScenario) async throws {
      try #require(String(localized: DiaryStringKey.participantEntryLabel) == "参与者", "快照必须加载应用的中文资源。")
      let fixture = try #require(ListSnapshotFixtures.shared.get().participantDetails[scenario])
      try await ParticipantSnapshotPreparation.prepareAvatars([fixture.participant])
      assertSnapshot(
        of: ParticipantDetailPreview(fixture: fixture),
        as: ListSnapshotConfiguration.image(
          style: scenario == .dark ? .dark : .light,
          contentSize: scenario == .accessibility ? .accessibilityExtraLarge : .large
        ),
        named: scenario.rawValue, record: ListSnapshotConfiguration.record,
        testName: "participant-detail"
      )
    }
  }
#endif
