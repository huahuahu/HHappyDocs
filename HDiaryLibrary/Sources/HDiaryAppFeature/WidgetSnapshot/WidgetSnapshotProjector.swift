import Foundation
import HDiaryWidgetData

nonisolated enum WidgetSnapshotProjector {
  static func project(
    participants: [WidgetParticipantSource],
    moments: [WidgetMomentSource],
    limit: Int,
    thumbnail: @Sendable (Data?) async -> Data?
  ) async -> WidgetSnapshotValue {
    let sortedParticipants = stableSortedParticipants(participants)
    let sortedMoments = stableSortedMoments(moments.filter { !$0.isDeleted })
    let boundedLimit = max(0, limit)
    var selectedMoments = [UUID: WidgetMomentSource]()

    for moment in sortedMoments.prefix(boundedLimit) {
      selectedMoments[moment.uuid] = moment
    }

    for participant in sortedParticipants {
      for moment in sortedMoments
        .lazy
        .filter({ $0.participantIDs.contains(participant.uuid) })
        .prefix(boundedLimit) {
        selectedMoments[moment.uuid] = moment
      }
    }

    var participantValues = [WidgetParticipantValue]()
    participantValues.reserveCapacity(sortedParticipants.count)
    for participant in sortedParticipants {
      participantValues.append(WidgetParticipantValue(
        uuid: participant.uuid,
        nickName: participant.nickName,
        avatarThumbnailData: await thumbnail(participant.avatarData)
      ))
    }

    let momentValues = stableSortedMoments(Array(selectedMoments.values)).map {
      WidgetMomentValue(
        uuid: $0.uuid,
        timestamp: $0.timestamp,
        title: $0.title,
        participantIDs: $0.participantIDs
      )
    }

    return WidgetSnapshotValue(participants: participantValues, moments: momentValues)
  }

  private static func stableSortedParticipants(
    _ participants: [WidgetParticipantSource]
  ) -> [WidgetParticipantSource] {
    participants.enumerated().sorted { lhs, rhs in
      let nameComparison = lhs.element.nickName.localizedStandardCompare(rhs.element.nickName)
      if nameComparison != .orderedSame {
        return nameComparison == .orderedAscending
      }

      let lhsUUID = lhs.element.uuid.uuidString
      let rhsUUID = rhs.element.uuid.uuidString
      if lhsUUID != rhsUUID {
        return lhsUUID < rhsUUID
      }

      return lhs.offset < rhs.offset
    }.map { $0.element }
  }

  private static func stableSortedMoments(_ moments: [WidgetMomentSource]) -> [WidgetMomentSource] {
    moments.enumerated().sorted { lhs, rhs in
      if lhs.element.timestamp != rhs.element.timestamp {
        return lhs.element.timestamp > rhs.element.timestamp
      }

      let lhsUUID = lhs.element.uuid.uuidString
      let rhsUUID = rhs.element.uuid.uuidString
      if lhsUUID != rhsUUID {
        return lhsUUID < rhsUUID
      }

      return lhs.offset < rhs.offset
    }.map { $0.element }
  }
}
