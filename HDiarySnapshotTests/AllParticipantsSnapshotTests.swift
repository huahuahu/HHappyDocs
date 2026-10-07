#if DEBUG && os(iOS)
  @testable import HDiaryAppFeature
  import SnapshotTesting
  import SwiftUI
  import Testing

  @Suite(.serialized)
  @MainActor
  struct AllParticipantsSnapshotTests {
    @Test("参与者列表整页", arguments: AllParticipantsPreviewScenario.allCases)
    func allParticipants(_ scenario: AllParticipantsPreviewScenario) async throws {
      try #require(String(localized: DiaryStringKey.participantEntryLabel) == "参与者", "快照必须加载应用的中文资源。")
      let fixture = try #require(ListSnapshotFixtures.shared.get().participants[scenario])
      try await ParticipantSnapshotPreparation.prepareAvatars(fixture.participants)
      assertSnapshot(
        of: AllParticipantsPreview(fixture: fixture),
        as: try ListSnapshotConfiguration.image(
          style: scenario == .dark ? .dark : .light,
          contentSize: scenario == .accessibility ? .accessibilityExtraLarge : .large
        ),
        named: try ListSnapshotConfiguration.name(scenario.rawValue), record: ListSnapshotConfiguration.record,
        testName: "all-participants"
      )
    }
  }
#endif
