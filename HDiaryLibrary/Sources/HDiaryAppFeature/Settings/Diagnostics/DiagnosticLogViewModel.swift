#if os(iOS)

  import Foundation
  import HDiaryConstants
  import Observation

  @MainActor @Observable
  final class DiagnosticLogViewModel {
    private let collector: DiagnosticLogCollector
    private var refreshID = UUID()

    var isEnabled: Bool
    private(set) var isLoading = false
    private(set) var report: DiagnosticLogReport?
    private(set) var errorMessage: String?

    init(collector: DiagnosticLogCollector = DiagnosticLogCollector()) {
      self.collector = collector
      isEnabled = DiagnosticLogging.isEnabled
    }

    func updateDiagnosticLogging(enabled: Bool) async {
      if enabled {
        DiagnosticLogging.setEnabled(true)
        Log.common.log(
          level: DiagnosticLogging.level(for: .info),
          "Diagnostic logging enabled"
        )
      }
      else {
        Log.common.log(
          level: DiagnosticLogging.level(for: .info),
          "Diagnostic logging disabled"
        )
        DiagnosticLogging.setEnabled(false)
      }
      isEnabled = enabled
      await refresh()
    }

    func refresh() async {
      let requestID = UUID()
      refreshID = requestID
      isLoading = true
      errorMessage = nil

      do {
        let collectedReport = try await collector.collect(since: DiagnosticLogging.startedAt)
        guard refreshID == requestID else {
          return
        }
        report = collectedReport
      }
      catch {
        guard refreshID == requestID else {
          return
        }
        errorMessage = error.localizedDescription
        Log.common.error("Failed to collect diagnostic logs: \(error)")
      }
      isLoading = false
    }
  }

#endif
