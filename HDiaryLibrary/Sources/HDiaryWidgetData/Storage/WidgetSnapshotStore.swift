import Foundation
import SwiftData

public actor WidgetSnapshotStore {
  private let modelContainer: ModelContainer

  public init(modelContainer: ModelContainer) {
    self.modelContainer = modelContainer
  }

  @discardableResult
  public func replace(with snapshot: WidgetSnapshotValue) throws -> Bool {
    let context = ModelContext(modelContainer)
    context.autosaveEnabled = false
    var hasChanges = false

    let existingParticipants = try context.fetch(FetchDescriptor<WidgetParticipantSnapshot>())
    let participantsByID = Dictionary(
      uniqueKeysWithValues: existingParticipants.map { ($0.uuid, $0) }
    )
    let desiredParticipantIDs = Set(snapshot.participants.map(\.uuid))

    for value in snapshot.participants {
      if let model = participantsByID[value.uuid] {
        if model.nickName != value.nickName {
          model.nickName = value.nickName
          hasChanges = true
        }
        if model.avatarThumbnailData != value.avatarThumbnailData {
          model.avatarThumbnailData = value.avatarThumbnailData
          hasChanges = true
        }
      } else {
        context.insert(
          WidgetParticipantSnapshot(
            uuid: value.uuid,
            nickName: value.nickName,
            avatarThumbnailData: value.avatarThumbnailData
          )
        )
        hasChanges = true
      }
    }

    for model in existingParticipants where !desiredParticipantIDs.contains(model.uuid) {
      context.delete(model)
      hasChanges = true
    }

    let existingMoments = try context.fetch(FetchDescriptor<WidgetMomentSnapshot>())
    let momentsByID = Dictionary(uniqueKeysWithValues: existingMoments.map { ($0.uuid, $0) })
    let desiredMomentIDs = Set(snapshot.moments.map(\.uuid))

    for value in snapshot.moments {
      if let model = momentsByID[value.uuid] {
        if model.timestamp != value.timestamp {
          model.timestamp = value.timestamp
          hasChanges = true
        }
        if model.title != value.title {
          model.title = value.title
          hasChanges = true
        }
        if Set(model.participantIDs) != Set(value.participantIDs) {
          model.participantIDs = value.participantIDs
          hasChanges = true
        }
      } else {
        context.insert(
          WidgetMomentSnapshot(
            uuid: value.uuid,
            timestamp: value.timestamp,
            title: value.title,
            participantIDs: value.participantIDs
          )
        )
        hasChanges = true
      }
    }

    for model in existingMoments where !desiredMomentIDs.contains(model.uuid) {
      context.delete(model)
      hasChanges = true
    }

    guard hasChanges else {
      return false
    }
    try context.save()
    return true
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
