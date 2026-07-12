import Foundation
import HDiaryModel
import HDiaryWidgetData
import SwiftData

@MainActor
struct MainStoreWidgetSnapshotBuilder {
  private let container: ModelContainer

  init(container: ModelContainer) {
    self.container = container
  }

  func build() async throws -> WidgetSnapshotValue {
    let context = ModelContext(container)
    context.autosaveEnabled = false

    let participants = try context.fetch(FetchDescriptor<Participant>())
    var momentDescriptor = FetchDescriptor<Moment>(
      sortBy: [SortDescriptor(\Moment.timestamp, order: .reverse)]
    )
    momentDescriptor.relationshipKeyPathsForPrefetching = [\Moment.participants]
    let moments = try context.fetch(momentDescriptor)

    let participantSources = participants.map {
      WidgetParticipantSource(uuid: $0.uuid, nickName: $0.nickName, avatarData: $0.avatar)
    }
    let momentSources = moments.map {
      WidgetMomentSource(
        uuid: $0.uuid,
        timestamp: $0.timestamp,
        title: $0.title,
        participantIDs: ($0.participants ?? []).map(\.uuid),
        isDeleted: $0.markedAsDelete
      )
    }

    return await WidgetSnapshotProjector.project(
      participants: participantSources,
      moments: momentSources,
      limit: 8,
      thumbnail: {
        await WidgetAvatarThumbnailer.thumbnailData(from: $0, maxPixelSize: 64)
      }
    )
  }
}
