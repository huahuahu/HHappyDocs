#if os(iOS)

  import Foundation

  struct CloudSyncEventPresentation {
    let state: CloudSyncEventRecord.State
    let kind: CloudSyncEventRecord.Kind
    let startDate: Date
    let endDate: Date?
    let duration: TimeInterval?
    let errorCodeText: String?
    let retryDate: Date?

    init(record: CloudSyncEventRecord) {
      state = record.state
      kind = record.kind
      startDate = record.startDate
      endDate = record.endDate
      duration = record.endDate.map { $0.timeIntervalSince(record.startDate) }
      errorCodeText = record.error.map { "\($0.domain) \($0.code)" }
      retryDate = record.error?.retryDate
    }
  }

#endif
