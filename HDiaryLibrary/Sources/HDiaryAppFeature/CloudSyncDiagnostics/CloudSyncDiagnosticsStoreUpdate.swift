import Foundation

nonisolated enum CloudSyncDiagnosticsStoreUpdate {
  case success(
    revision: UInt64,
    records: [CloudSyncEventRecord],
    exportURL: URL
  )
  case failure(revision: UInt64, description: String)
}
