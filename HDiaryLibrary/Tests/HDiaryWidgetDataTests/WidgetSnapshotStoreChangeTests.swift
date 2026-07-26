import Foundation
import SwiftData
@testable import HDiaryWidgetData
import Testing

struct WidgetSnapshotStoreChangeTests {
  @Test("首次 replace 报告变化，相同内容的第二次 replace 报告 no-op")
  func reportsChangedThenUnchanged() async throws {
    let store = try makeStore()
    let snapshot = WidgetSnapshotValue(
      participants: [participant(id: 1, name: "Tiger")],
      moments: [moment(id: 1, title: "Moment", participantIDs: [fixedUUID(1)])]
    )

    let firstChanged = try await store.replace(with: snapshot)
    let secondChanged = try await store.replace(with: snapshot)

    #expect(firstChanged)
    #expect(!secondChanged)
    #expect(try await store.snapshot() == snapshot)
  }

  @Test("participantIDs 只有顺序不同不触发保存")
  func participantOrderIsNotAChange() async throws {
    let store = try makeStore()
    let first = WidgetSnapshotValue(
      participants: [],
      moments: [moment(id: 1, title: "Moment", participantIDs: [fixedUUID(1), fixedUUID(2)])]
    )
    let reordered = WidgetSnapshotValue(
      participants: [],
      moments: [moment(id: 1, title: "Moment", participantIDs: [fixedUUID(2), fixedUUID(1)])]
    )

    #expect(try await store.replace(with: first))
    let changed = try await store.replace(with: reordered)
    let persisted = try await store.snapshot()

    #expect(!changed)
    #expect(Set(persisted.moments.first?.participantIDs ?? []) == Set([fixedUUID(1), fixedUUID(2)]))
  }

  @Test("Participant 或 Moment 持久字段变化会保存并返回 true")
  func persistedFieldChangesAreReported() async throws {
    let store = try makeStore()
    let first = WidgetSnapshotValue(
      participants: [participant(id: 1, name: "Old")],
      moments: [moment(id: 1, title: "Old", participantIDs: [fixedUUID(1)])]
    )
    let updated = WidgetSnapshotValue(
      participants: [participant(id: 1, name: "New")],
      moments: [moment(id: 1, title: "New", participantIDs: [fixedUUID(2)])]
    )

    _ = try await store.replace(with: first)
    #expect(try await store.replace(with: updated))
    #expect(try await store.snapshot() == updated)
  }

  @Test("仅 avatarThumbnailData 变化会保存并持久化更新值")
  func avatarThumbnailDataOnlyChangeIsReported() async throws {
    let store = try makeStore()
    let first = WidgetSnapshotValue(
      participants: [participant(id: 1, name: "Tiger", avatarThumbnailData: Data([0x01]))],
      moments: []
    )
    let updated = WidgetSnapshotValue(
      participants: [participant(id: 1, name: "Tiger", avatarThumbnailData: Data([0x02]))],
      moments: []
    )

    _ = try await store.replace(with: first)
    let secondChanged = try await store.replace(with: updated)

    #expect(secondChanged)
    #expect(try await store.snapshot() == updated)
  }

  @Test("仅 timestamp 变化会保存并持久化更新值")
  func timestampOnlyChangeIsReported() async throws {
    let store = try makeStore()
    let first = WidgetSnapshotValue(
      participants: [],
      moments: [
        moment(
          id: 1,
          title: "Moment",
          participantIDs: [fixedUUID(1)],
          timestamp: Date(timeIntervalSince1970: 1)
        )
      ]
    )
    let updated = WidgetSnapshotValue(
      participants: [],
      moments: [
        moment(
          id: 1,
          title: "Moment",
          participantIDs: [fixedUUID(1)],
          timestamp: Date(timeIntervalSince1970: 2)
        )
      ]
    )

    _ = try await store.replace(with: first)
    let secondChanged = try await store.replace(with: updated)

    #expect(secondChanged)
    #expect(try await store.snapshot() == updated)
  }

  @Test("增加或移除记录会保存并清理过期记录")
  func insertionsAndDeletionsAreReported() async throws {
    let store = try makeStore()
    let first = WidgetSnapshotValue(
      participants: [participant(id: 1, name: "Keep"), participant(id: 2, name: "Delete")],
      moments: [moment(id: 1, title: "Delete", participantIDs: [])]
    )
    let second = WidgetSnapshotValue(
      participants: [participant(id: 1, name: "Keep")],
      moments: [moment(id: 2, title: "Insert", participantIDs: [])]
    )

    _ = try await store.replace(with: first)
    #expect(try await store.replace(with: second))
    #expect(try await store.snapshot() == second)
  }

  private func makeStore() throws -> WidgetSnapshotStore {
    let schema = Schema([WidgetParticipantSnapshot.self, WidgetMomentSnapshot.self])
    let configuration = ModelConfiguration(
      schema: schema,
      isStoredInMemoryOnly: true,
      cloudKitDatabase: .none
    )
    return WidgetSnapshotStore(
      modelContainer: try ModelContainer(for: schema, configurations: [configuration])
    )
  }

  private func fixedUUID(_ value: Int) -> UUID {
    UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", value))!
  }

  private func participant(
    id: Int,
    name: String,
    avatarThumbnailData: Data? = nil
  ) -> WidgetParticipantValue {
    WidgetParticipantValue(
      uuid: fixedUUID(id),
      nickName: name,
      avatarThumbnailData: avatarThumbnailData
    )
  }

  private func moment(
    id: Int,
    title: String,
    participantIDs: [UUID],
    timestamp: Date? = nil
  ) -> WidgetMomentValue {
    WidgetMomentValue(
      uuid: fixedUUID(1_000 + id),
      timestamp: timestamp ?? Date(timeIntervalSince1970: TimeInterval(id)),
      title: title,
      participantIDs: participantIDs
    )
  }
}
