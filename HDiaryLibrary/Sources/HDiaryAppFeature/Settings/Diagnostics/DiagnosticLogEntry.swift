import Foundation
import OSLog

nonisolated enum DiagnosticLogLevel: String, Sendable {
  case notice
  case error
  case fault

  init?(systemLevel: OSLogEntryLog.Level) {
    switch systemLevel {
    case .notice:
      self = .notice
    case .error:
      self = .error
    case .fault:
      self = .fault
    case .undefined, .debug, .info:
      return nil
    @unknown default:
      return nil
    }
  }
}

nonisolated struct DiagnosticLogEntry: Identifiable, Sendable {
  let id: UUID
  let date: Date
  let category: String
  let level: DiagnosticLogLevel
  let message: String

  init(
    id: UUID = UUID(),
    date: Date,
    category: String,
    level: DiagnosticLogLevel,
    message: String
  ) {
    self.id = id
    self.date = date
    self.category = category
    self.level = level
    self.message = message
  }
}
