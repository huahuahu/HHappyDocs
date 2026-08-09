#if os(iOS)

  @testable import HDiaryWidgetSnapshotSync
  import Foundation
  import HDiaryModel
  import HDiaryWidgetData
  import SwiftData
  import Testing

  struct MainStoreWidgetSnapshotSourceReaderTests {
    @Test("reader actor 映射有效主 Store 模型为 Sendable source values")
    func mapsParticipantsMomentsDeletionAndRelationships() async throws {
      let fixture = try makeFixture()
      let reader = MainStoreWidgetSnapshotSourceReader(container: fixture.container)

      let source = try await reader.read(limit: 8)

      #expect(source.participants == [
        WidgetParticipantSource(
          uuid: fixture.participantID,
          nickName: "P",
          avatarData: Data([1, 2, 3])
        ),
      ])
      #expect(source.moments.first { $0.uuid == fixture.activeMomentID } == WidgetMomentSource(
        uuid: fixture.activeMomentID,
        timestamp: Date(timeIntervalSince1970: 1000),
        title: "Active",
        participantIDs: [fixture.participantID],
        isDeleted: false
      ))
      #expect(source.moments.contains { $0.uuid == fixture.deletedMomentID } == false)
    }

    @Test("reader 只读取全局及每位 Participant 最近 8 条有效 Moment")
    func readsBoundedGlobalAndPerParticipantUnion() async throws {
      let schema = Schema([Tag.self, Moment.self, MediaItem.self, HappyImage.self, Participant.self])
      let configuration = ModelConfiguration(
        schema: schema,
        isStoredInMemoryOnly: true,
        cloudKitDatabase: .none
      )
      let container = try ModelContainer(for: schema, configurations: [configuration])
      let context = ModelContext(container)
      context.autosaveEnabled = false
      let firstParticipant = Participant.create(name: "First", nickName: "A")
      let secondParticipant = Participant.create(name: "Second", nickName: "B")
      context.insert(firstParticipant)
      context.insert(secondParticipant)

      var expectedTitles = Set<String>()
      expectedTitles.formUnion(insertMoments(
        prefix: "Global",
        startingTimestamp: 3000,
        participant: nil,
        context: context
      ))
      expectedTitles.formUnion(insertMoments(
        prefix: "First",
        startingTimestamp: 2000,
        participant: firstParticipant,
        context: context
      ))
      expectedTitles.formUnion(insertMoments(
        prefix: "Second",
        startingTimestamp: 1000,
        participant: secondParticipant,
        context: context
      ))

      let deletedMoment = Moment.create(timestamp: Date(timeIntervalSince1970: 4000))
      deletedMoment.updateTitle("Deleted")
      deletedMoment.updateParticipants([firstParticipant])
      deletedMoment.markAsDelete()
      context.insert(deletedMoment)
      try context.save()

      let source = try await MainStoreWidgetSnapshotSourceReader(container: container).read(limit: 8)

      #expect(source.participants.count == 2)
      #expect(source.moments.count == 24)
      #expect(Set(source.moments.map { $0.title }) == expectedTitles)
      #expect(source.moments.contains { $0.uuid == deletedMoment.uuid } == false)
    }

    @Test("相同时间的 Moment 使用 UUID 稳定截断")
    func breaksTimestampTiesByUUID() async throws {
      let schema = Schema([Tag.self, Moment.self, MediaItem.self, HappyImage.self, Participant.self])
      let configuration = ModelConfiguration(
        schema: schema,
        isStoredInMemoryOnly: true,
        cloudKitDatabase: .none
      )
      let container = try ModelContainer(for: schema, configurations: [configuration])
      let context = ModelContext(container)
      context.autosaveEnabled = false
      var momentIDs = [UUID]()

      for index in 0 ..< 9 {
        let moment = Moment.create(timestamp: Date(timeIntervalSince1970: 1000))
        moment.updateTitle("Moment-\(index)")
        context.insert(moment)
        momentIDs.append(moment.uuid)
      }
      try context.save()

      let source = try await MainStoreWidgetSnapshotSourceReader(container: container).read(limit: 8)
      let expectedIDs = Set(momentIDs.sorted { $0.uuidString < $1.uuidString }.prefix(8))

      #expect(source.moments.count == 8)
      #expect(Set(source.moments.map(\.uuid)) == expectedIDs)
    }

    @Test("reader 对全局和多人查询命中的同一 Moment 只返回一次")
    func deduplicatesSharedMomentAcrossQueries() async throws {
      let schema = Schema([Tag.self, Moment.self, MediaItem.self, HappyImage.self, Participant.self])
      let configuration = ModelConfiguration(
        schema: schema,
        isStoredInMemoryOnly: true,
        cloudKitDatabase: .none
      )
      let container = try ModelContainer(for: schema, configurations: [configuration])
      let context = ModelContext(container)
      let firstParticipant = Participant.create(name: "First", nickName: "A")
      let secondParticipant = Participant.create(name: "Second", nickName: "B")
      let sharedMoment = Moment.create(timestamp: Date(timeIntervalSince1970: 1000))
      sharedMoment.updateTitle("Shared")
      sharedMoment.updateParticipants([firstParticipant, secondParticipant])
      context.insert(firstParticipant)
      context.insert(secondParticipant)
      context.insert(sharedMoment)
      try context.save()

      let source = try await MainStoreWidgetSnapshotSourceReader(container: container).read(limit: 8)

      #expect(source.moments.map(\.uuid) == [sharedMoment.uuid])
    }

    @Test("limit 为零时仍返回 Participant 但不读取 Moment")
    func zeroLimitReturnsParticipantsWithoutMoments() async throws {
      let fixture = try makeFixture()

      let source = try await MainStoreWidgetSnapshotSourceReader(
        container: fixture.container
      ).read(limit: 0)

      #expect(source.participants.map(\.uuid) == [fixture.participantID])
      #expect(source.moments.isEmpty)
    }

    @Test("builder 可在非 MainActor actor 中创建并执行")
    func builderBuildsOutsideMainActor() async throws {
      let fixture = try makeFixture()

      let snapshot = try await NonMainActorBuilderProbe().build(
        container: fixture.container
      )

      #expect(snapshot.participants.map(\.uuid) == [fixture.participantID])
      #expect(snapshot.moments.map(\.uuid) == [fixture.activeMomentID])
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
      let activeMoment = Moment.create(timestamp: Date(timeIntervalSince1970: 1000))
      activeMoment.updateTitle("Active")
      activeMoment.updateParticipants([participant])
      let deletedMoment = Moment.create(timestamp: Date(timeIntervalSince1970: 2000))
      deletedMoment.updateTitle("Deleted")
      deletedMoment.updateParticipants([participant])
      deletedMoment.markAsDelete()
      context.insert(participant)
      context.insert(activeMoment)
      context.insert(deletedMoment)
      try context.save()
      return (container, participant.uuid, activeMoment.uuid, deletedMoment.uuid)
    }

    private func insertMoments(
      prefix: String,
      startingTimestamp: TimeInterval,
      participant: Participant?,
      context: ModelContext
    ) -> Set<String> {
      var expectedTitles = Set<String>()

      for index in 0 ..< 10 {
        let title = "\(prefix)-\(index)"
        let moment = Moment.create(
          timestamp: Date(timeIntervalSince1970: startingTimestamp - TimeInterval(index))
        )
        moment.updateTitle(title)
        moment.updateParticipants(participant.map { [$0] } ?? [])
        context.insert(moment)

        if index < 8 {
          expectedTitles.insert(title)
        }
      }

      return expectedTitles
    }
  }

  private actor NonMainActorBuilderProbe {
    func build(container: ModelContainer) async throws -> WidgetSnapshotValue {
      let builder = MainStoreWidgetSnapshotBuilder(container: container)
      return try await builder.build()
    }
  }

#endif
