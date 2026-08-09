import Foundation
import SwiftData

/// Widget 独立 Store 中持久化的轻量 Moment 快照。
@Model
public final class WidgetMomentSnapshot {
  @Attribute(.unique) public var uuid: UUID = UUID()
  public var timestamp: Date = Date.distantPast
  public var title: String = ""
  /// 只保存参与者 UUID，不建立与主业务模型的 SwiftData relationship。
  public var participantIDs: [UUID] = []

  public init(uuid: UUID, timestamp: Date, title: String, participantIDs: [UUID]) {
    self.uuid = uuid
    self.timestamp = timestamp
    self.title = title
    self.participantIDs = participantIDs
  }
}
