#if os(iOS)

  import Foundation

  struct CloudSyncEventPresentation {
    let state: CloudSyncEventRecord.State
    let kind: CloudSyncEventRecord.Kind
    let errorCodeText: String?
    let retryDate: Date?

    init(record: CloudSyncEventRecord) {
      state = record.state
      kind = record.kind
      errorCodeText = record.error.map { "\($0.domain) \($0.code)" }
      retryDate = record.error?.retryDate
    }
  }

#endif
