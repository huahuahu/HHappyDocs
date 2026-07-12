import Foundation
import HDiaryConstants
import Observation

@MainActor @Observable
final class CloudSyncDiagnosticsModel {
  private let fileStore: CloudSyncDiagnosticsFileStore

  private(set) var records: [CloudSyncEventRecord] = []
  private(set) var loadErrorDescription: String?
  private(set) var exportURL: URL?

  init(fileStore: CloudSyncDiagnosticsFileStore = CloudSyncDiagnosticsFileStore()) {
    self.fileStore = fileStore
  }

  func load() async {
    do {
      let loadedRecords = try await fileStore.load()
      let loadedExportURL = try await fileStore.exportURL()
      records = loadedRecords
      exportURL = loadedExportURL
      loadErrorDescription = nil
    }
    catch {
      Log.data.error("Failed to load CloudKit sync diagnostics: \(error.localizedDescription)")
      loadErrorDescription = error.localizedDescription
    }
  }

  func record(_ event: CloudSyncEventRecord) async {
    do {
      let updatedRecords = try await fileStore.upsert(event)
      let updatedExportURL = try await fileStore.exportURL()
      records = updatedRecords
      exportURL = updatedExportURL
      loadErrorDescription = nil
    }
    catch {
      Log.data.error("Failed to record CloudKit sync diagnostics: \(error.localizedDescription)")
      loadErrorDescription = error.localizedDescription
    }
  }
}
