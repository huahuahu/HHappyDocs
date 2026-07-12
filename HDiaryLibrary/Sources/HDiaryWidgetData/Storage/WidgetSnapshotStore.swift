import Foundation
import SwiftData

public actor WidgetSnapshotStore {
  private let modelContainer: ModelContainer

  public init(modelContainer: ModelContainer) {
    self.modelContainer = modelContainer
  }

  public func replace(with snapshot: WidgetSnapshotValue) throws {
    let context = ModelContext(modelContainer)
    context.autosaveEnabled = false

    let existingParticipants = try context.fetch(FetchDescriptor<WidgetParticipantSnapshot>())
    let participantsByID = Dictionary(
      uniqueKeysWithValues: existingParticipants.map { ($0.uuid, $0) }
    )
    let desiredParticipantIDs = Set(snapshot.participants.map(\.uuid))

    for value in snapshot.participants {
      if let model = participantsByID[value.uuid] {
        model.nickName = value.nickName
        model.avatarThumbnailData = value.avatarThumbnailData
      } else {
        context.insert(
          WidgetParticipantSnapshot(
            uuid: value.uuid,
            nickName: value.nickName,
            avatarThumbnailData: value.avatarThumbnailData
          )
        )
      }
    }

    for model in existingParticipants where !desiredParticipantIDs.contains(model.uuid) {
      context.delete(model)
    }

    let existingMoments = try context.fetch(FetchDescriptor<WidgetMomentSnapshot>())
    let momentsByID = Dictionary(uniqueKeysWithValues: existingMoments.map { ($0.uuid, $0) })
    let desiredMomentIDs = Set(snapshot.moments.map(\.uuid))

    for value in snapshot.moments {
      if let model = momentsByID[value.uuid] {
        model.timestamp = value.timestamp
        model.title = value.title
        model.participantIDs = value.participantIDs
      } else {
        context.insert(
          WidgetMomentSnapshot(
            uuid: value.uuid,
            timestamp: value.timestamp,
            title: value.title,
            participantIDs: value.participantIDs
          )
        )
      }
    }

    for model in existingMoments where !desiredMomentIDs.contains(model.uuid) {
      context.delete(model)
    }

    try context.save()
  }

  public func snapshot() throws -> WidgetSnapshotValue {
    let context = ModelContext(modelContainer)
    let participants = try context.fetch(
      FetchDescriptor<WidgetParticipantSnapshot>(
        sortBy: [SortDescriptor(\.nickName), SortDescriptor(\.uuid)]
      )
    )
    let moments = try context.fetch(
      FetchDescriptor<WidgetMomentSnapshot>(
        sortBy: [SortDescriptor(\.timestamp, order: .reverse), SortDescriptor(\.uuid)]
      )
    )

    return WidgetSnapshotValue(
      participants: participants.map(WidgetParticipantValue.init),
      moments: moments.map(WidgetMomentValue.init)
    )
  }
}
