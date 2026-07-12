#if os(iOS)

  import Foundation
  import HDiaryConstants

  actor CloudSyncDiagnosticsFileStore {
    private static let maximumRecordCount = 100
    private static let fileName = "cloud-sync-events.json"
    private static let corruptFileName = "cloud-sync-events.corrupt.json"

    private let directoryURL: URL
    private let fileURL: URL
    private let corruptFileURL: URL
    private var updateRevision: UInt64 = 0

    init(
      directoryURL: URL = AppConstants.groupContainerURL
        .appending(
          components: "Library",
          "Application Support",
          "Diagnostics",
          directoryHint: .isDirectory
        )
    ) {
      self.directoryURL = directoryURL
      fileURL = directoryURL.appending(path: Self.fileName)
      corruptFileURL = directoryURL.appending(path: Self.corruptFileName)
    }

    func loadUpdate() async -> CloudSyncDiagnosticsStoreUpdate {
      let revision = nextUpdateRevision()
      do {
        let records = try load()
        let exportURL = try exportURL()
        return .success(revision: revision, records: records, exportURL: exportURL)
      }
      catch {
        return .failure(revision: revision, description: error.localizedDescription)
      }
    }

    func recordUpdate(
      _ event: CloudSyncEventRecord
    ) async -> CloudSyncDiagnosticsStoreUpdate {
      let revision = nextUpdateRevision()
      do {
        let records = try upsert(event)
        let exportURL = try exportURL()
        return .success(revision: revision, records: records, exportURL: exportURL)
      }
      catch {
        return .failure(revision: revision, description: error.localizedDescription)
      }
    }

    @discardableResult
    func upsert(_ event: CloudSyncEventRecord) throws -> [CloudSyncEventRecord] {
      var records = try load()

      if let index = records.firstIndex(where: { $0.id == event.id }) {
        if records[index].isEnded, event.state == .inProgress {
          return records
        }
        records[index] = event
      }
      else {
        records.append(event)
      }

      let sortedRecords = stableStartDateSort(records)
      let boundedRecords = Array(sortedRecords.suffix(Self.maximumRecordCount))
      try write(boundedRecords)
      return boundedRecords
    }

    func load() throws -> [CloudSyncEventRecord] {
      try prepareDirectory()
      guard FileManager.default.fileExists(atPath: fileURL.path) else {
        return []
      }

      let data = try Data(contentsOf: fileURL)
      do {
        return try makeDecoder().decode([CloudSyncEventRecord].self, from: data)
      }
      catch {
        try quarantineCorruptData(data)
        return []
      }
    }

    func exportURL() throws -> URL {
      let records = try load()
      if !FileManager.default.fileExists(atPath: fileURL.path) {
        try write(records)
      }
      return fileURL
    }

    private func stableStartDateSort(
      _ records: [CloudSyncEventRecord]
    ) -> [CloudSyncEventRecord] {
      records.enumerated().sorted { lhs, rhs in
        if lhs.element.startDate != rhs.element.startDate {
          return lhs.element.startDate < rhs.element.startDate
        }
        return lhs.offset < rhs.offset
      }.map(\.element)
    }

    private func nextUpdateRevision() -> UInt64 {
      updateRevision &+= 1
      return updateRevision
    }

    private func write(_ records: [CloudSyncEventRecord]) throws {
      try prepareDirectory()
      let data = try makeEncoder().encode(records)
      try data.write(to: fileURL, options: [.atomic])
      try applyFileProtection(to: fileURL)
    }

    private func quarantineCorruptData(_ data: Data) throws {
      try prepareDirectory()
      try data.write(to: corruptFileURL, options: [.atomic])
      try applyFileProtection(to: corruptFileURL)
      try FileManager.default.removeItem(at: fileURL)
    }

    private func prepareDirectory() throws {
      try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
      var directoryURL = directoryURL
      var resourceValues = URLResourceValues()
      resourceValues.isExcludedFromBackup = true
      try directoryURL.setResourceValues(resourceValues)
    }

    private func applyFileProtection(to url: URL) throws {
      #if os(iOS)
        try FileManager.default.setAttributes(
          [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
          ofItemAtPath: url.path
        )
      #endif
    }

    private func makeEncoder() -> JSONEncoder {
      let encoder = JSONEncoder()
      encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
      encoder.dateEncodingStrategy = .iso8601
      return encoder
    }

    private func makeDecoder() -> JSONDecoder {
      let decoder = JSONDecoder()
      decoder.dateDecodingStrategy = .iso8601
      return decoder
    }
  }

  private extension CloudSyncEventRecord {
    nonisolated var isEnded: Bool {
      endDate != nil || state != .inProgress
    }
  }

#endif
