import Foundation
import SwiftData

/// Widget 独立 Store 中持久化的轻量 Participant 快照。
@Model
public final class WidgetParticipantSnapshot {
  @Attribute(.unique) public var uuid: UUID = UUID()
  public var nickName: String = ""
  /// 仅保存 Widget 展示所需的头像缩略图，不复制原始头像。
  public var avatarThumbnailData: Data?

  public init(uuid: UUID, nickName: String, avatarThumbnailData: Data?) {
    self.uuid = uuid
    self.nickName = nickName
    self.avatarThumbnailData = avatarThumbnailData
  }
}
