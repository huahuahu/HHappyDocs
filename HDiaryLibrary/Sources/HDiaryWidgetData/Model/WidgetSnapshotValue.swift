import Foundation

public struct WidgetParticipantValue: Sendable, Equatable {
  public let uuid: UUID
  public let nickName: String
  public let avatarThumbnailData: Data?

  public init(uuid: UUID, nickName: String, avatarThumbnailData: Data?) {
    self.uuid = uuid
    self.nickName = nickName
    self.avatarThumbnailData = avatarThumbnailData
  }

  public init(_ model: WidgetParticipantSnapshot) {
    self.init(
      uuid: model.uuid,
      nickName: model.nickName,
      avatarThumbnailData: model.avatarThumbnailData
    )
  }
}

public struct WidgetMomentValue: Sendable, Equatable {
  public let uuid: UUID
  public let timestamp: Date
  public let title: String
  public let participantIDs: [UUID]

  public init(uuid: UUID, timestamp: Date, title: String, participantIDs: [UUID]) {
    self.uuid = uuid
    self.timestamp = timestamp
    self.title = title
    self.participantIDs = participantIDs
  }

  public init(_ model: WidgetMomentSnapshot) {
    self.init(
      uuid: model.uuid,
      timestamp: model.timestamp,
      title: model.title,
      participantIDs: model.participantIDs
    )
  }
}

public struct WidgetSnapshotValue: Sendable, Equatable {
  public let participants: [WidgetParticipantValue]
  public let moments: [WidgetMomentValue]

  public init(participants: [WidgetParticipantValue], moments: [WidgetMomentValue]) {
    self.participants = participants
    self.moments = moments
  }
}
