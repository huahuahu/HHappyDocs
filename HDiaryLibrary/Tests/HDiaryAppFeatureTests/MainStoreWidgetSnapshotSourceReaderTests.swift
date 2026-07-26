#if os(iOS)

  @testable import HDiaryAppFeature
  import Foundation
  import HDiaryModel
  import SwiftData
  import Testing

  struct MainStoreWidgetSnapshotSourceReaderTests {
    @Test("reader actor 映射主 Store 模型为 Sendable source values")
    func mapsParticipantsMomentsDeletionAndRelationships() async throws {
      let fixture = try makeFixture()
      let reader = MainStoreWidgetSnapshotSourceReader(container: fixture.container)

      let source = try await reader.read()

      #expect(source.participants == [
        WidgetParticipantSource(
          uuid: fixture.participantID,
          nickName: "P",
          avatarData: Data([1, 2, 3])
        ),
      ])
      #expect(source.moments.first { $0.uuid == fixture.activeMomentID } == WidgetMomentSource(
        uuid: fixture.activeMomentID,
        timestamp: Date(timeIntervalSince1970: 1_000),
        title: "Active",
        participantIDs: [fixture.participantID],
        isDeleted: false
      ))
      #expect(source.moments.first { $0.uuid == fixture.deletedMomentID }?.isDeleted == true)
    }

    private func makeFixture() throws -> (
      container: ModelContainer,
      participantID: UUID,
      activeMomentID: UUID,
      deletedMomentID: UUID
    ) {
      let schema = Schema([Tag.self, Moment.self, MediaItem.self, HappyImage.self, Participant.self])
      let configuration = ModelConfiguration(
        schema: schema,
        isStoredInMemoryOnly: true,
        cloudKitDatabase: .none
      )
      let container = try ModelContainer(for: schema, configurations: [configuration])
      let context = ModelContext(container)
      context.autosaveEnabled = false
      let participant = Participant.create(
        name: "Participant",
        nickName: "P",
        avatar: Data([1, 2, 3])
      )
      let activeMoment = Moment.create(timestamp: Date(timeIntervalSince1970: 1_000))
      activeMoment.updateTitle("Active")
      activeMoment.updateParticipants([participant])
      let deletedMoment = Moment.create(timestamp: Date(timeIntervalSince1970: 2_000))
      deletedMoment.updateTitle("Deleted")
      deletedMoment.updateParticipants([participant])
      deletedMoment.markAsDelete()
      context.insert(participant)
      context.insert(activeMoment)
      context.insert(deletedMoment)
      try context.save()
      return (container, participant.uuid, activeMoment.uuid, deletedMoment.uuid)
    }
  }

#endif
