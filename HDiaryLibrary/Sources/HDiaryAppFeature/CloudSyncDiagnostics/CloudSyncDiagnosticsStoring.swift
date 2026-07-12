protocol CloudSyncDiagnosticsStoring: Sendable {
  func loadUpdate() async -> CloudSyncDiagnosticsStoreUpdate
  func recordUpdate(
    _ event: CloudSyncEventRecord
  ) async -> CloudSyncDiagnosticsStoreUpdate
}

extension CloudSyncDiagnosticsFileStore: CloudSyncDiagnosticsStoring {}
