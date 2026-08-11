#if os(iOS)

  @testable import HDiaryAppFeature
  import Foundation
  import OSLog
  import Testing

  struct DiagnosticLogReportTests {
    @Test("Only persistent diagnostic and error levels are exportable")
    func includedLevels() {
      #expect(DiagnosticLogLevel(systemLevel: .undefined) == nil)
      #expect(DiagnosticLogLevel(systemLevel: .debug) == nil)
      #expect(DiagnosticLogLevel(systemLevel: .info) == nil)
      #expect(DiagnosticLogLevel(systemLevel: .notice) == .notice)
      #expect(DiagnosticLogLevel(systemLevel: .error) == .error)
      #expect(DiagnosticLogLevel(systemLevel: .fault) == .fault)
    }

    @Test("Reports sort entries and produce a complete text export")
    func formattingAndSorting() throws {
      let firstID = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000001"))
      let secondID = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000002"))
      let firstDate = Date(timeIntervalSince1970: 1_700_000_001)
      let secondDate = Date(timeIntervalSince1970: 1_700_000_002)
      let report = DiagnosticLogReport(
        generatedAt: Date(timeIntervalSince1970: 1_700_000_003),
        sessionStartedAt: Date(timeIntervalSince1970: 1_700_000_000),
        entries: [
          DiagnosticLogEntry(
            id: secondID,
            date: secondDate,
            category: "widget.snapshot",
            level: .error,
            message: "second"
          ),
          DiagnosticLogEntry(
            id: firstID,
            date: firstDate,
            category: "data",
            level: .notice,
            message: "first"
          ),
        ]
      )

      #expect(report.entries.map(\.id) == [firstID, secondID])
      #expect(report.text.contains("Subsystem: com.tiger.suzhou.hdiary"))
      #expect(report.text.contains("Entry count: 2"))
      #expect(report.text.contains("Widget extension logs are not included"))

      let firstRange = try #require(report.text.range(of: "[NOTICE] [data] first"))
      let secondRange = try #require(report.text.range(of: "[ERROR] [widget.snapshot] second"))
      #expect(firstRange.lowerBound < secondRange.lowerBound)
    }
  }

#endif
