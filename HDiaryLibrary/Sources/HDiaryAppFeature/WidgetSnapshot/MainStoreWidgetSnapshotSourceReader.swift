#if os(iOS)

  import Foundation
  import HDiaryModel
  import SwiftData

  actor MainStoreWidgetSnapshotSourceReader {
    private let container: ModelContainer

    init(container: ModelContainer) {
      self.container = container
    }

    func read() throws -> WidgetSnapshotSourceValue {
      let context = ModelContext(container)
      context.autosaveEnabled = false

      let participants = try context.fetch(FetchDescriptor<Participant>())
      var momentDescriptor = FetchDescriptor<Moment>(
        sortBy: [SortDescriptor(\Moment.timestamp, order: .reverse)]
      )
      momentDescriptor.relationshipKeyPathsForPrefetching = [\Moment.participants]
      let moments = try context.fetch(momentDescriptor)

      return WidgetSnapshotSourceValue(
        participants: participants.map {
          WidgetParticipantSource(uuid: $0.uuid, nickName: $0.nickName, avatarData: $0.avatar)
        },
        moments: moments.map {
          WidgetMomentSource(
            uuid: $0.uuid,
            timestamp: $0.timestamp,
            title: $0.title,
            participantIDs: ($0.participants ?? []).map(\.uuid),
            isDeleted: $0.markedAsDelete
          )
        }
      )
    }
  }

#endif
