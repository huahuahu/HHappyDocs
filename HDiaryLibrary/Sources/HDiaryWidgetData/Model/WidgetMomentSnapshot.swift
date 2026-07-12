import Foundation
import SwiftData

@Model
public final class WidgetMomentSnapshot {
  @Attribute(.unique) public var uuid: UUID = UUID()
  public var timestamp: Date = Date.distantPast
  public var title: String = ""
  public var participantIDs: [UUID] = []

  public init(uuid: UUID, timestamp: Date, title: String, participantIDs: [UUID]) {
    self.uuid = uuid
    self.timestamp = timestamp
    self.title = title
    self.participantIDs = participantIDs
  }
}
