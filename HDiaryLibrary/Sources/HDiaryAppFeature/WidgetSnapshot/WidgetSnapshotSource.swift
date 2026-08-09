#if os(iOS)

  import Foundation

  /// 跨 actor 传递 Participant 快照输入所需的纯值数据。
  // swiftformat:disable:next redundantSendable
  nonisolated struct WidgetParticipantSource: Sendable, Equatable {
    let uuid: UUID
    let nickName: String
    let avatarData: Data?
  }

  /// 跨 actor 传递 Moment 快照输入所需的纯值数据。
  // swiftformat:disable:next redundantSendable
  nonisolated struct WidgetMomentSource: Sendable, Equatable {
    let uuid: UUID
    let timestamp: Date
    let title: String
    let participantIDs: [UUID]
    let isDeleted: Bool
  }

  /// 汇总一次投影所需的全部主 Store 纯值数据。
  // swiftformat:disable:next redundantSendable
  nonisolated struct WidgetSnapshotSourceValue: Sendable, Equatable {
    let participants: [WidgetParticipantSource]
    let moments: [WidgetMomentSource]
  }

#endif
