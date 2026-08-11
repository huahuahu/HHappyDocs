@testable import HDiaryConstants
import Foundation
import OSLog
import Testing

struct DiagnosticLoggingTests {
  @Test("Log levels retain their source level until diagnostics are enabled")
  func levelMapping() {
    #expect(
      DiagnosticLogging.level(for: .debug, diagnosticsEnabled: false).rawValue
        == OSLogType.debug.rawValue
    )
    #expect(
      DiagnosticLogging.level(for: .info, diagnosticsEnabled: false).rawValue
        == OSLogType.info.rawValue
    )
    #expect(
      DiagnosticLogging.level(for: .debug, diagnosticsEnabled: true).rawValue
        == OSLogType.default.rawValue
    )
    #expect(
      DiagnosticLogging.level(for: .info, diagnosticsEnabled: true).rawValue
        == OSLogType.default.rawValue
    )
  }

  @Test("Enabling diagnostics persists the switch and session start time")
  func persistenceAndSessionTime() throws {
    let suiteName = "DiagnosticLoggingTests.persistence.\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defaults.removePersistentDomain(forName: suiteName)
    defer { defaults.removePersistentDomain(forName: suiteName) }

    let firstStart = Date(timeIntervalSince1970: 1_700_000_000.125)
    let state = DiagnosticLoggingState(suiteName: suiteName)
    state.setEnabled(true, now: firstStart)

    #expect(state.isEnabled)
    #expect(state.startedAt == firstStart)

    let restored = DiagnosticLoggingState(suiteName: suiteName)
    #expect(restored.isEnabled)
    #expect(restored.startedAt == firstStart)

    state.setEnabled(false)
    #expect(state.isEnabled == false)
    #expect(state.startedAt == firstStart)

    let secondStart = Date(timeIntervalSince1970: 1_700_000_100.5)
    state.setEnabled(true, now: secondStart)
    #expect(state.startedAt == secondStart)
  }

  @Test("Refreshing reloads state written by another process")
  func refreshFromSharedDefaults() throws {
    let suiteName = "DiagnosticLoggingTests.refresh.\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defaults.removePersistentDomain(forName: suiteName)
    defer { defaults.removePersistentDomain(forName: suiteName) }

    let reader = DiagnosticLoggingState(suiteName: suiteName)
    let writer = DiagnosticLoggingState(suiteName: suiteName)
    let start = Date(timeIntervalSince1970: 1_700_000_200.75)

    writer.setEnabled(true, now: start)
    #expect(reader.isEnabled == false)

    reader.refreshFromDefaults()
    #expect(reader.isEnabled)
    #expect(reader.startedAt == start)
  }

  @Test("Atomic diagnostic state supports concurrent reads")
  func concurrentReads() async throws {
    let suiteName = "DiagnosticLoggingTests.concurrent.\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defaults.removePersistentDomain(forName: suiteName)
    defer { defaults.removePersistentDomain(forName: suiteName) }

    let state = DiagnosticLoggingState(suiteName: suiteName)
    state.setEnabled(true, now: Date(timeIntervalSince1970: 1_700_000_300))

    await withTaskGroup(of: Void.self) { group in
      for _ in 0 ..< 20 {
        group.addTask {
          for _ in 0 ..< 1000 {
            _ = state.isEnabled
            _ = state.startedAt
          }
        }
      }
    }

    #expect(state.isEnabled)
    #expect(state.startedAt != nil)
  }
}
