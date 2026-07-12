#if os(iOS)

  @testable import HDiaryAppFeature
  import CloudKit
  import Foundation
  import XCTest

  @MainActor
  final class CloudSyncDiagnosticsTests: XCTestCase {
    private let fixedStart = Date(timeIntervalSince1970: 1000)
    private let expectedRetryDate = Date(timeIntervalSince1970: 1060)

    func testEventPresentationExposesSemanticValues() {
      let inProgressImport = record(id: 1, kind: .importData, state: .inProgress)
      let successfulExport = record(id: 2, kind: .export, state: .succeeded)
      let failedSetup = record(
        id: 3,
        kind: .setup,
        state: .failed,
        error: CloudSyncErrorDetails(
          domain: NSCocoaErrorDomain,
          code: 134_410,
          message: "CloudKit setup failed",
          retryAfter: nil,
          retryDate: nil
        )
      )
      let rateLimited = record(
        id: 4,
        kind: .export,
        state: .failed,
        error: CloudSyncErrorDetails(
          domain: CKErrorDomain,
          code: CKError.requestRateLimited.rawValue,
          message: "Request rate limited",
          retryAfter: 60,
          retryDate: expectedRetryDate
        )
      )

      XCTAssertEqual(CloudSyncEventPresentation(record: inProgressImport).state, .inProgress)
      XCTAssertEqual(CloudSyncEventPresentation(record: successfulExport).state, .succeeded)
      XCTAssertEqual(
        CloudSyncEventPresentation(record: failedSetup).errorCodeText,
        "NSCocoaErrorDomain 134410"
      )
      XCTAssertEqual(
        CloudSyncEventPresentation(record: rateLimited).retryDate,
        expectedRetryDate
      )
    }

    func testEventRecordPreservesExactKindsAndStatesThroughCodable() throws {
      let records = [
        makeEvent(start: 1, kind: .setup, state: .inProgress),
        makeEvent(start: 2, end: 3, kind: .importData, state: .succeeded),
        makeEvent(start: 4, end: 5, kind: .export, state: .failed),
      ]

      let data = try JSONEncoder().encode(records)
      let decoded = try JSONDecoder().decode([CloudSyncEventRecord].self, from: data)

      XCTAssertEqual(decoded, records)
      XCTAssertEqual(CloudSyncEventRecord.Kind.setup.rawValue, "setup")
      XCTAssertEqual(CloudSyncEventRecord.Kind.importData.rawValue, "importData")
      XCTAssertEqual(CloudSyncEventRecord.Kind.export.rawValue, "export")
      XCTAssertEqual(CloudSyncEventRecord.State.inProgress.rawValue, "inProgress")
      XCTAssertEqual(CloudSyncEventRecord.State.succeeded.rawValue, "succeeded")
      XCTAssertEqual(CloudSyncEventRecord.State.failed.rawValue, "failed")
    }

    func testRetryAfterIsFoundInNestedPartialErrorWithoutReplacingTopLevelCode() throws {
      let retrying = NSError(
        domain: CKErrorDomain,
        code: CKError.requestRateLimited.rawValue,
        userInfo: [CKErrorRetryAfterKey: NSNumber(value: 60)]
      )
      let outer = NSError(
        domain: CKErrorDomain,
        code: CKError.partialFailure.rawValue,
        userInfo: [
          NSLocalizedDescriptionKey: "Partial failure",
          CKPartialErrorsByItemIDKey: ["record": retrying],
        ]
      )
      let now = Date(timeIntervalSince1970: 1000)

      let details = try XCTUnwrap(CloudSyncErrorDetails.from(error: outer, now: now))

      XCTAssertEqual(details.domain, CKErrorDomain)
      XCTAssertEqual(details.code, CKError.partialFailure.rawValue)
      XCTAssertEqual(details.message, "CloudKit operation failed")
      XCTAssertEqual(details.retryAfter, 60)
      XCTAssertEqual(details.retryDate, Date(timeIntervalSince1970: 1060))
    }

    func testSensitiveErrorTextIsExcludedFromDetailsAndEncodedDiagnostics() throws {
      let recordIDSentinel = "RECORD-ID-SENTINEL-76F2"
      let userIDSentinel = "USER-ID-SENTINEL-76F2"
      let diaryContentSentinel = "DIARY-CONTENT-SENTINEL-76F2"
      let error = NSError(
        domain: CKErrorDomain,
        code: CKError.requestRateLimited.rawValue,
        userInfo: [
          NSLocalizedDescriptionKey:
            "\(recordIDSentinel)|\(userIDSentinel)|\(diaryContentSentinel)",
          NSLocalizedFailureReasonErrorKey: userIDSentinel,
          NSLocalizedRecoverySuggestionErrorKey: diaryContentSentinel,
          CKErrorRetryAfterKey: NSNumber(value: 45),
        ]
      )
      let now = Date(timeIntervalSince1970: 1000)

      let details = try XCTUnwrap(CloudSyncErrorDetails.from(error: error, now: now))
      let record = CloudSyncEventRecord(
        id: UUID(),
        storeIdentifier: "primary",
        kind: .importData,
        startDate: now,
        endDate: now.addingTimeInterval(1),
        state: .failed,
        error: details
      )
      let json = try String(decoding: JSONEncoder().encode([record]), as: UTF8.self)

      XCTAssertEqual(details.domain, CKErrorDomain)
      XCTAssertEqual(details.code, CKError.requestRateLimited.rawValue)
      XCTAssertEqual(details.message, "CloudKit operation failed")
      XCTAssertEqual(details.retryAfter, 45)
      XCTAssertEqual(details.retryDate, Date(timeIntervalSince1970: 1045))
      for sentinel in [recordIDSentinel, userIDSentinel, diaryContentSentinel] {
        XCTAssertFalse(details.message.contains(sentinel))
        XCTAssertFalse(json.contains(sentinel))
      }
    }

    func testRetryAfterTraversesUnderlyingAndMultipleErrors() throws {
      let retrying = NSError(
        domain: CKErrorDomain,
        code: CKError.serviceUnavailable.rawValue,
        userInfo: [CKErrorRetryAfterKey: NSNumber(value: 30)]
      )
      let multiple = NSError(
        domain: NSCocoaErrorDomain,
        code: 2,
        userInfo: [
          NSMultipleUnderlyingErrorsKey: [
            NSError(domain: NSCocoaErrorDomain, code: 1),
            retrying,
          ],
        ]
      )
      let outer = NSError(
        domain: NSCocoaErrorDomain,
        code: 3,
        userInfo: [NSUnderlyingErrorKey: multiple]
      )

      let details = try XCTUnwrap(
        CloudSyncErrorDetails.from(error: outer, now: Date(timeIntervalSince1970: 100))
      )

      XCTAssertEqual(details.message, "Persistent data operation failed")
      XCTAssertEqual(details.retryAfter, 30)
      XCTAssertEqual(details.retryDate, Date(timeIntervalSince1970: 130))
    }

    func testRetryAfterUsesCurrentErrorBeforeNestedErrors() throws {
      let nested = NSError(
        domain: CKErrorDomain,
        code: CKError.requestRateLimited.rawValue,
        userInfo: [CKErrorRetryAfterKey: NSNumber(value: 60)]
      )
      let outer = NSError(
        domain: CKErrorDomain,
        code: CKError.serviceUnavailable.rawValue,
        userInfo: [
          CKErrorRetryAfterKey: NSNumber(value: 5),
          NSUnderlyingErrorKey: nested,
        ]
      )

      let details = try XCTUnwrap(
        CloudSyncErrorDetails.from(error: outer, now: Date(timeIntervalSince1970: 100))
      )

      XCTAssertEqual(details.retryAfter, 5)
      XCTAssertEqual(details.retryDate, Date(timeIntervalSince1970: 105))
    }

    func testRetryAfterRejectsNonNSNumberAndNegativeValues() throws {
      let stringValue = NSError(
        domain: CKErrorDomain,
        code: CKError.requestRateLimited.rawValue,
        userInfo: [CKErrorRetryAfterKey: "60"]
      )
      let negativeValue = NSError(
        domain: CKErrorDomain,
        code: CKError.requestRateLimited.rawValue,
        userInfo: [CKErrorRetryAfterKey: NSNumber(value: -1)]
      )

      let stringDetails = try XCTUnwrap(CloudSyncErrorDetails.from(error: stringValue))
      let negativeDetails = try XCTUnwrap(CloudSyncErrorDetails.from(error: negativeValue))

      XCTAssertNil(stringDetails.retryAfter)
      XCTAssertNil(stringDetails.retryDate)
      XCTAssertNil(negativeDetails.retryAfter)
      XCTAssertNil(negativeDetails.retryDate)
    }

    func testRetryAfterTraversalStopsAtNSErrorCycles() throws {
      let nestedErrors = NSMutableArray()
      let cyclic = NSError(
        domain: NSCocoaErrorDomain,
        code: 1,
        userInfo: [NSMultipleUnderlyingErrorsKey: nestedErrors]
      )
      nestedErrors.add(cyclic)

      let details = try XCTUnwrap(CloudSyncErrorDetails.from(error: cyclic))

      XCTAssertNil(details.retryAfter)
      XCTAssertNil(details.retryDate)
    }

    func testUpsertCompletesOneEventAndDoesNotDowngradeItToInProgress() async throws {
      let directoryURL = try makeTemporaryDirectory()
      defer { try? FileManager.default.removeItem(at: directoryURL) }
      let store = CloudSyncDiagnosticsFileStore(directoryURL: directoryURL)
      let id = UUID()
      let started = makeEvent(id: id, start: 1, state: .inProgress)
      let succeeded = makeEvent(id: id, start: 1, end: 2, state: .succeeded)

      _ = try await store.upsert(started)
      let completedRecords = try await store.upsert(succeeded)
      let recordsAfterLateProgress = try await store.upsert(started)
      let loadedRecords = try await store.load()

      XCTAssertEqual(completedRecords, [succeeded])
      XCTAssertEqual(recordsAfterLateProgress, [succeeded])
      XCTAssertEqual(loadedRecords, [succeeded])
    }

    func testUpsertKeepsNewestHundredEventsInStableStartDateOrder() async throws {
      let directoryURL = try makeTemporaryDirectory()
      defer { try? FileManager.default.removeItem(at: directoryURL) }
      let store = CloudSyncDiagnosticsFileStore(directoryURL: directoryURL)

      for index in 0 ..< 105 {
        _ = try await store.upsert(makeEvent(start: TimeInterval(index), state: .inProgress))
      }

      let records = try await store.load()

      XCTAssertEqual(records.count, 100)
      XCTAssertEqual(
        records.map(\.startDate),
        (5 ..< 105).map { Date(timeIntervalSince1970: TimeInterval($0)) }
      )
    }

    func testCorruptJSONIsQuarantinedOnceAndDoesNotPoisonFuturePrimaryData() async throws {
      let directoryURL = try makeTemporaryDirectory()
      defer { try? FileManager.default.removeItem(at: directoryURL) }
      let store = CloudSyncDiagnosticsFileStore(directoryURL: directoryURL)
      let primaryURL = directoryURL.appending(path: "cloud-sync-events.json")
      let corruptURL = directoryURL.appending(path: "cloud-sync-events.corrupt.json")
      let invalidData = Data("{not valid json".utf8)
      try invalidData.write(to: primaryURL)

      let records = try await store.load()

      XCTAssertTrue(records.isEmpty)
      XCTAssertFalse(FileManager.default.fileExists(atPath: primaryURL.path))
      XCTAssertEqual(try Data(contentsOf: corruptURL), invalidData)
      let corruptFiles = try FileManager.default.contentsOfDirectory(
        at: directoryURL,
        includingPropertiesForKeys: nil
      ).filter { $0.lastPathComponent.contains(".corrupt") }
      XCTAssertEqual(corruptFiles.map(\.lastPathComponent), ["cloud-sync-events.corrupt.json"])

      let recovered = makeEvent(start: 10, end: 11, state: .succeeded)
      _ = try await store.upsert(recovered)
      let recoveredRecords = try await store.load()

      XCTAssertEqual(recoveredRecords, [recovered])
      XCTAssertEqual(try Data(contentsOf: corruptURL), invalidData)
    }

    func testExportCreatesStableProtectedPrettyPrintedISO8601JSON() async throws {
      let directoryURL = try makeApplicationSupportDirectory()
      defer { try? FileManager.default.removeItem(at: directoryURL) }
      let store = CloudSyncDiagnosticsFileStore(directoryURL: directoryURL)
      let event = makeEvent(start: 1000, end: 1060, kind: .export, state: .failed)
      _ = try await store.upsert(event)

      let firstURL = try await store.exportURL()
      let secondURL = try await store.exportURL()
      let json = try String(decoding: Data(contentsOf: firstURL), as: UTF8.self)

      XCTAssertEqual(firstURL, secondURL)
      XCTAssertEqual(firstURL.lastPathComponent, "cloud-sync-events.json")
      XCTAssertTrue(json.contains("\n"))
      XCTAssertTrue(json.contains("1970-01-01T00:16:40Z"))
      let idIndex = try XCTUnwrap(json.range(of: "\"id\""))
      let kindIndex = try XCTUnwrap(json.range(of: "\"kind\""))
      let startDateIndex = try XCTUnwrap(json.range(of: "\"startDate\""))
      let stateIndex = try XCTUnwrap(json.range(of: "\"state\""))
      let storeIdentifierIndex = try XCTUnwrap(json.range(of: "\"storeIdentifier\""))
      XCTAssertLessThan(idIndex.lowerBound, kindIndex.lowerBound)
      XCTAssertLessThan(kindIndex.lowerBound, startDateIndex.lowerBound)
      XCTAssertLessThan(startDateIndex.lowerBound, stateIndex.lowerBound)
      XCTAssertLessThan(stateIndex.lowerBound, storeIdentifierIndex.lowerBound)
      XCTAssertEqual(
        try JSONDecoder.iso8601.decode([CloudSyncEventRecord].self, from: Data(json.utf8)),
        [event]
      )

      let directoryValues = try directoryURL.resourceValues(forKeys: [.isExcludedFromBackupKey])
      XCTAssertEqual(directoryValues.isExcludedFromBackup, true)
      #if os(iOS)
        let protectionValues = try firstURL.resourceValues(forKeys: [.fileProtectionKey])
        #if targetEnvironment(simulator)
          if let fileProtection = protectionValues.fileProtection {
            XCTAssertEqual(fileProtection, .completeUntilFirstUserAuthentication)
          }
          else {
            XCTContext.runActivity(
              named: "Simulator does not expose the file protection resource value"
            ) { _ in }
          }
        #else
          XCTAssertEqual(
            protectionValues.fileProtection,
            .completeUntilFirstUserAuthentication
          )
        #endif
      #endif
    }

    func testExportCreatesEmptyJSONWhenNoEventsExist() async throws {
      let directoryURL = try makeTemporaryDirectory()
      defer { try? FileManager.default.removeItem(at: directoryURL) }
      let store = CloudSyncDiagnosticsFileStore(directoryURL: directoryURL)

      let exportURL = try await store.exportURL()

      XCTAssertEqual(
        try JSONDecoder.iso8601.decode([CloudSyncEventRecord].self, from: Data(contentsOf: exportURL)),
        []
      )
    }

    func testModelRecordsAndLoadsOnlyActorReturnedValues() async throws {
      let directoryURL = try makeTemporaryDirectory()
      defer { try? FileManager.default.removeItem(at: directoryURL) }
      let store = CloudSyncDiagnosticsFileStore(directoryURL: directoryURL)
      let model = CloudSyncDiagnosticsModel(fileStore: store)
      let event = makeEvent(start: 1, end: 2, state: .succeeded)

      await model.record(event)

      XCTAssertEqual(model.records, [event])
      XCTAssertNil(model.loadErrorDescription)
      XCTAssertNotNil(model.exportURL)

      let reloadedModel = CloudSyncDiagnosticsModel(fileStore: store)
      await reloadedModel.load()

      XCTAssertEqual(reloadedModel.records, [event])
      XCTAssertNil(reloadedModel.loadErrorDescription)
      XCTAssertEqual(reloadedModel.exportURL, model.exportURL)
    }

    func testModelExposesLoadFailureDescription() async throws {
      let temporaryDirectory = try makeTemporaryDirectory()
      defer { try? FileManager.default.removeItem(at: temporaryDirectory) }
      let blockedDirectoryURL = temporaryDirectory.appending(path: "not-a-directory")
      try Data("file".utf8).write(to: blockedDirectoryURL)
      let store = CloudSyncDiagnosticsFileStore(directoryURL: blockedDirectoryURL)
      let model = CloudSyncDiagnosticsModel(fileStore: store)

      await model.load()

      XCTAssertFalse(model.loadErrorDescription?.isEmpty ?? true)
      XCTAssertTrue(model.records.isEmpty)
      XCTAssertNil(model.exportURL)
    }

    func testOlderLoadSuccessDoesNotReplaceNewerRecordedState() async {
      let store = SuspendedLoadDiagnosticsStore()
      let model = CloudSyncDiagnosticsModel(fileStore: store)
      let event = makeEvent(start: 1, end: 2, state: .succeeded)
      let loadTask = Task { @MainActor in
        await model.load()
      }
      await store.waitUntilLoadIsPending()

      await model.record(event)

      XCTAssertEqual(model.records, [event])
      XCTAssertNil(model.loadErrorDescription)

      await store.resumeLoad(with: [])
      await loadTask.value

      XCTAssertEqual(model.records, [event])
      XCTAssertNil(model.loadErrorDescription)
    }

    func testOlderLoadFailureDoesNotReplaceNewerRecordedState() async {
      let store = SuspendedLoadDiagnosticsStore()
      let model = CloudSyncDiagnosticsModel(fileStore: store)
      let event = makeEvent(start: 1, end: 2, state: .succeeded)
      let loadTask = Task { @MainActor in
        await model.load()
      }
      await store.waitUntilLoadIsPending()

      await model.record(event)

      XCTAssertEqual(model.records, [event])
      XCTAssertNil(model.loadErrorDescription)

      await store.failLoad(description: "stale load failure")
      await loadTask.value

      XCTAssertEqual(model.records, [event])
      XCTAssertNil(model.loadErrorDescription)
    }

    func testOlderLoadSuccessStillUpdatesRecordsAfterNewerFailureArrivesFirst() async {
      let failureDescription = "newer record failure"
      let store = SuspendedLoadDiagnosticsStore(
        recordFailureDescription: failureDescription
      )
      let model = CloudSyncDiagnosticsModel(fileStore: store)
      let loadedEvent = makeEvent(start: 1, end: 2, state: .succeeded)
      let failedEvent = makeEvent(start: 3, end: 4, state: .failed)
      let loadTask = Task { @MainActor in
        await model.load()
      }
      await store.waitUntilLoadIsPending()

      await model.record(failedEvent)

      XCTAssertEqual(model.records, [])
      XCTAssertEqual(model.loadErrorDescription, failureDescription)

      await store.resumeLoad(with: [loadedEvent])
      await loadTask.value

      XCTAssertEqual(model.records, [loadedEvent])
      XCTAssertEqual(model.loadErrorDescription, failureDescription)
    }

    func testNewerSuccessClearsPreviouslyAppliedFailure() async {
      let store = SuspendedLoadDiagnosticsStore()
      let model = CloudSyncDiagnosticsModel(fileStore: store)
      let event = makeEvent(start: 1, end: 2, state: .succeeded)
      let loadTask = Task { @MainActor in
        await model.load()
      }
      await store.waitUntilLoadIsPending()

      await store.failLoad(description: "older load failure")
      await loadTask.value

      XCTAssertEqual(model.loadErrorDescription, "older load failure")

      await model.record(event)

      XCTAssertEqual(model.records, [event])
      XCTAssertNil(model.loadErrorDescription)
    }

    func testEqualRevisionSuccessUpdatesRecordsWithoutClearingFailure() async {
      let failureDescription = "same revision failure"
      let store = SuspendedLoadDiagnosticsStore(
        recordFailureDescription: failureDescription,
        recordAdvancesRevision: false
      )
      let model = CloudSyncDiagnosticsModel(fileStore: store)
      let loadedEvent = makeEvent(start: 1, end: 2, state: .succeeded)
      let failedEvent = makeEvent(start: 3, end: 4, state: .failed)
      let loadTask = Task { @MainActor in
        await model.load()
      }
      await store.waitUntilLoadIsPending()

      await model.record(failedEvent)

      XCTAssertEqual(model.loadErrorDescription, failureDescription)

      await store.resumeLoad(with: [loadedEvent])
      await loadTask.value

      XCTAssertEqual(model.records, [loadedEvent])
      XCTAssertEqual(model.loadErrorDescription, failureDescription)
    }

    func testEqualRevisionFailureOverridesPreviouslyAppliedSuccess() async {
      let failureDescription = "same revision failure"
      let store = SuspendedLoadDiagnosticsStore(recordAdvancesRevision: false)
      let model = CloudSyncDiagnosticsModel(fileStore: store)
      let event = makeEvent(start: 1, end: 2, state: .succeeded)
      let loadTask = Task { @MainActor in
        await model.load()
      }
      await store.waitUntilLoadIsPending()

      await model.record(event)

      XCTAssertEqual(model.records, [event])
      XCTAssertNil(model.loadErrorDescription)

      await store.failLoad(description: failureDescription)
      await loadTask.value

      XCTAssertEqual(model.records, [event])
      XCTAssertEqual(model.loadErrorDescription, failureDescription)
    }

    private func makeEvent(
      id: UUID = UUID(),
      start: TimeInterval,
      end: TimeInterval? = nil,
      kind: CloudSyncEventRecord.Kind = .setup,
      state: CloudSyncEventRecord.State
    ) -> CloudSyncEventRecord {
      CloudSyncEventRecord(
        id: id,
        storeIdentifier: "primary",
        kind: kind,
        startDate: Date(timeIntervalSince1970: start),
        endDate: end.map(Date.init(timeIntervalSince1970:)),
        state: state,
        error: nil
      )
    }

    private func record(
      id: Int,
      kind: CloudSyncEventRecord.Kind,
      state: CloudSyncEventRecord.State,
      error: CloudSyncErrorDetails? = nil
    ) -> CloudSyncEventRecord {
      CloudSyncEventRecord(
        id: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", id))!,
        storeIdentifier: "primary",
        kind: kind,
        startDate: fixedStart,
        endDate: state == .inProgress ? nil : fixedStart.addingTimeInterval(10),
        state: state,
        error: error
      )
    }

    private func makeTemporaryDirectory() throws -> URL {
      let url = FileManager.default.temporaryDirectory
        .appending(path: "CloudSyncDiagnosticsTests-\(UUID().uuidString)", directoryHint: .isDirectory)
      try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
      return url
    }

    private func makeApplicationSupportDirectory() throws -> URL {
      let rootURL = try XCTUnwrap(
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
      )
      let url = rootURL
        .appending(path: "CloudSyncDiagnosticsTests-\(UUID().uuidString)", directoryHint: .isDirectory)
      try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
      return url
    }
  }

  private extension JSONDecoder {
    static var iso8601: JSONDecoder {
      let decoder = JSONDecoder()
      decoder.dateDecodingStrategy = .iso8601
      return decoder
    }
  }

  private actor SuspendedLoadDiagnosticsStore: CloudSyncDiagnosticsStoring {
    private let exportURL = URL(filePath: "/tmp/cloud-sync-events.json")
    private let recordFailureDescription: String?
    private let recordAdvancesRevision: Bool
    private var revision: UInt64 = 0
    private var pendingLoad: (
      revision: UInt64,
      continuation: CheckedContinuation<CloudSyncDiagnosticsStoreUpdate, Never>
    )?
    private var loadStartedContinuation: CheckedContinuation<Void, Never>?

    init(
      recordFailureDescription: String? = nil,
      recordAdvancesRevision: Bool = true
    ) {
      self.recordFailureDescription = recordFailureDescription
      self.recordAdvancesRevision = recordAdvancesRevision
    }

    func loadUpdate() async -> CloudSyncDiagnosticsStoreUpdate {
      revision &+= 1
      let loadRevision = revision

      return await withCheckedContinuation { continuation in
        pendingLoad = (loadRevision, continuation)
        loadStartedContinuation?.resume()
        loadStartedContinuation = nil
      }
    }

    func recordUpdate(
      _ event: CloudSyncEventRecord
    ) async -> CloudSyncDiagnosticsStoreUpdate {
      if recordAdvancesRevision {
        revision &+= 1
      }
      if let recordFailureDescription {
        return .failure(revision: revision, description: recordFailureDescription)
      }
      return .success(revision: revision, records: [event], exportURL: exportURL)
    }

    func waitUntilLoadIsPending() async {
      guard pendingLoad == nil else {
        return
      }

      await withCheckedContinuation { continuation in
        loadStartedContinuation = continuation
      }
    }

    func resumeLoad(with records: [CloudSyncEventRecord]) {
      guard let pendingLoad else {
        return
      }
      self.pendingLoad = nil
      pendingLoad.continuation.resume(
        returning: .success(
          revision: pendingLoad.revision,
          records: records,
          exportURL: exportURL
        )
      )
    }

    func failLoad(description: String) {
      guard let pendingLoad else {
        return
      }
      self.pendingLoad = nil
      pendingLoad.continuation.resume(
        returning: .failure(
          revision: pendingLoad.revision,
          description: description
        )
      )
    }
  }

#endif
