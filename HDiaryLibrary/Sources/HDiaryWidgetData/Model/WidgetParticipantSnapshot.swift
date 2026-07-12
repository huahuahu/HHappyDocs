import Foundation
import SwiftData

@Model
public final class WidgetParticipantSnapshot {
  @Attribute(.unique) public var uuid: UUID = UUID()
  public var nickName: String = ""
  public var avatarThumbnailData: Data?

  public init(uuid: UUID, nickName: String, avatarThumbnailData: Data?) {
    self.uuid = uuid
    self.nickName = nickName
    self.avatarThumbnailData = avatarThumbnailData
  }
}
