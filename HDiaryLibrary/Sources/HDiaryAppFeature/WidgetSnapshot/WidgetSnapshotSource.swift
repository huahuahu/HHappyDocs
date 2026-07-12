#if os(iOS)

  import Foundation

  // swiftformat:disable:next redundantSendable
  nonisolated struct WidgetParticipantSource: Sendable, Equatable {
    let uuid: UUID
    let nickName: String
    let avatarData: Data?
  }

  // swiftformat:disable:next redundantSendable
  nonisolated struct WidgetMomentSource: Sendable, Equatable {
    let uuid: UUID
    let timestamp: Date
    let title: String
    let participantIDs: [UUID]
    let isDeleted: Bool
  }

#endif
