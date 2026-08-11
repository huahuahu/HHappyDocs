import Foundation
import HDiaryConstants

nonisolated struct DiagnosticLogReport {
  let generatedAt: Date
  let sessionStartedAt: Date?
  let entries: [DiagnosticLogEntry]

  init(
    generatedAt: Date = .now,
    sessionStartedAt: Date?,
    entries: [DiagnosticLogEntry]
  ) {
    self.generatedAt = generatedAt
    self.sessionStartedAt = sessionStartedAt
    self.entries = entries.sorted { lhs, rhs in
      if lhs.date != rhs.date {
        return lhs.date < rhs.date
      }
      return lhs.id.uuidString < rhs.id.uuidString
    }
  }

  var text: String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    let sessionStart = sessionStartedAt.map { formatter.string(from: $0) } ?? "Not available"

    var lines = [
      "HDiary Diagnostic Logs",
      "Generated: \(formatter.string(from: generatedAt))",
      "Session started: \(sessionStart)",
      "Subsystem: \(Log.subsystem)",
      "Process scope: current app process",
      "Entry count: \(entries.count)",
      "Widget extension logs are not included in this export.",
      "",
    ]

    lines.append(contentsOf: entries.map { entry in
      let timestamp = formatter.string(from: entry.date)
      return "[\(timestamp)] [\(entry.level.rawValue.uppercased())] [\(entry.category)] \(entry.message)"
    })
    return lines.joined(separator: "\n") + "\n"
  }
}
