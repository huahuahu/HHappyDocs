#if os(iOS)

  import Foundation
  import HDiaryConstants
  import Observation

  @MainActor @Observable
  final class CloudSyncDiagnosticsModel {
    static let shared = CloudSyncDiagnosticsModel()

    private let fileStore: any CloudSyncDiagnosticsStoring
    private var appliedDataRevision: UInt64 = 0
    private var appliedErrorRevision: UInt64 = 0

    private(set) var records: [CloudSyncEventRecord] = []
    private(set) var loadErrorDescription: String?
    private(set) var exportURL: URL?

    init(
      fileStore: any CloudSyncDiagnosticsStoring = CloudSyncDiagnosticsFileStore()
    ) {
      self.fileStore = fileStore
    }

    func load() async {
      let update = await fileStore.loadUpdate()
      apply(update, failureLogPrefix: "Failed to load CloudKit sync diagnostics")
    }

    func record(_ event: CloudSyncEventRecord) async {
      let update = await fileStore.recordUpdate(event)
      apply(update, failureLogPrefix: "Failed to record CloudKit sync diagnostics")
    }

    private func apply(
      _ update: CloudSyncDiagnosticsStoreUpdate,
      failureLogPrefix: String
    ) {
      switch update {
      case .success(let revision, let updatedRecords, let updatedExportURL):
        if revision > appliedDataRevision {
          appliedDataRevision = revision
          records = updatedRecords
          exportURL = updatedExportURL
        }
        if revision > appliedErrorRevision {
          appliedErrorRevision = revision
          loadErrorDescription = nil
        }
      case .failure(let revision, let description):
        guard revision >= appliedErrorRevision else {
          return
        }
        appliedErrorRevision = revision
        Log.data.error("\(failureLogPrefix): \(description)")
        loadErrorDescription = description
      }
    }
  }

#endif
