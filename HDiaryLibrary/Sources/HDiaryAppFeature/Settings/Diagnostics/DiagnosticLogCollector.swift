import Foundation
import HDiaryConstants
import OSLog

nonisolated struct DiagnosticLogCollector: Sendable {
  @concurrent
  func collect(
    since sessionStartedAt: Date?,
    generatedAt: Date = .now
  ) async throws -> DiagnosticLogReport {
    let store = try OSLogStore(scope: .currentProcessIdentifier)
    let predicate = NSPredicate(format: "subsystem == %@", Log.subsystem)
    let sequence: AnySequence<OSLogEntry>

    if let sessionStartedAt {
      let position = store.position(date: sessionStartedAt)
      sequence = AnySequence(try store.getEntries(at: position, matching: predicate))
    }
    else {
      sequence = AnySequence(try store.getEntries(matching: predicate))
    }

    let entries = sequence.compactMap { item -> DiagnosticLogEntry? in
      guard let log = item as? OSLogEntryLog,
            log.subsystem == Log.subsystem,
            let level = DiagnosticLogLevel(systemLevel: log.level)
      else {
        return nil
      }

      return DiagnosticLogEntry(
        date: log.date,
        category: log.category,
        level: level,
        message: log.composedMessage
      )
    }

    return DiagnosticLogReport(
      generatedAt: generatedAt,
      sessionStartedAt: sessionStartedAt,
      entries: entries
    )
  }
}
