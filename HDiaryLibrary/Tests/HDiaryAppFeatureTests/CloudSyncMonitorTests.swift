#if os(iOS)

  @testable import HDiaryAppFeature
  import CoreData
  import Foundation
  import HDiaryWidgetData
  import SwiftData
  import XCTest

  @MainActor
  final class CloudSyncMonitorTests: XCTestCase {
    func testDefaultMonitorUsesSharedDiagnosticsModel() {
      let monitor = CloudSyncMonitor()

      XCTAssertTrue(monitor.diagnosticsModel === CloudSyncDiagnosticsModel.shared)
    }

    func testMonitorKeepsInjectedDiagnosticsModel() throws {
      let directoryURL = try makeTemporaryDirectory()
      defer { try? FileManager.default.removeItem(at: directoryURL) }
      let model = CloudSyncDiagnosticsModel(
        fileStore: CloudSyncDiagnosticsFileStore(directoryURL: directoryURL)
      )

      let monitor = CloudSyncMonitor(diagnosticsModel: model)

      XCTAssertTrue(monitor.diagnosticsModel === model)
    }

    func testEventTypesMapToDiagnosticKindsWithoutPersistingStoreIdentifier() throws {
      let identifier = UUID()
      let startDate = Date(timeIntervalSince1970: 100)
      let now = Date(timeIntervalSince1970: 200)
      let cases: [(NSPersistentCloudKitContainer.EventType, CloudSyncEventRecord.Kind)] = [
        (.setup, .setup),
        (.import, .importData),
        (.export, .export),
      ]

      for (eventType, expectedKind) in cases {
        let record = try XCTUnwrap(
          CloudSyncEventRecord(
            input: CloudSyncEventInput(
              identifier: identifier,
              type: eventType,
              startDate: startDate,
              endDate: nil,
              succeeded: false,
              error: nil
            ),
            now: now
          )
        )

        XCTAssertEqual(record.id, identifier)
        XCTAssertEqual(record.storeIdentifier, "primary")
        XCTAssertEqual(record.kind, expectedKind)
        XCTAssertEqual(record.startDate, startDate)
      }
    }

    func testEventCompletionMapsToInProgressSucceededAndFailedStates() throws {
      let startDate = Date(timeIntervalSince1970: 100)
      let endDate = Date(timeIntervalSince1970: 150)
      let now = Date(timeIntervalSince1970: 200)
      let failure = NSError(
        domain: "CloudSyncMonitorTests",
        code: 7,
        userInfo: [NSLocalizedDescriptionKey: "failed"]
      )

      let inProgress = try XCTUnwrap(
        CloudSyncEventRecord(
          input: CloudSyncEventInput(
            identifier: UUID(),
            type: .setup,
            startDate: startDate,
            endDate: nil,
            succeeded: false,
            error: nil
          ),
          now: now
        )
      )
      let succeeded = try XCTUnwrap(
        CloudSyncEventRecord(
          input: CloudSyncEventInput(
            identifier: UUID(),
            type: .import,
            startDate: startDate,
            endDate: endDate,
            succeeded: true,
            error: nil
          ),
          now: now
        )
      )
      let failed = try XCTUnwrap(
        CloudSyncEventRecord(
          input: CloudSyncEventInput(
            identifier: UUID(),
            type: .export,
            startDate: startDate,
            endDate: endDate,
            succeeded: false,
            error: failure
          ),
          now: now
        )
      )

      XCTAssertEqual(inProgress.state, .inProgress)
      XCTAssertNil(inProgress.endDate)
      XCTAssertNil(inProgress.error)
      XCTAssertEqual(succeeded.state, .succeeded)
      XCTAssertEqual(succeeded.endDate, endDate)
      XCTAssertNil(succeeded.error)
      XCTAssertEqual(failed.state, .failed)
      XCTAssertEqual(failed.endDate, endDate)
      XCTAssertEqual(failed.error?.domain, failure.domain)
      XCTAssertEqual(failed.error?.code, failure.code)
      XCTAssertEqual(failed.error?.message, "Synchronization operation failed")
    }

    func testRemoteChangeMatchesOnlyPrimaryStoreURL() {
      let primaryStoreURL = URL(filePath: "/tmp/primary.sqlite")
      let snapshotStoreURL = URL(filePath: "/tmp/widget-snapshot.sqlite")
      let matching = Notification(
        name: .NSPersistentStoreRemoteChange,
        object: nil,
        userInfo: [NSPersistentStoreURLKey: primaryStoreURL]
      )
      let other = Notification(
        name: .NSPersistentStoreRemoteChange,
        object: nil,
        userInfo: [NSPersistentStoreURLKey: snapshotStoreURL]
      )

      XCTAssertTrue(CloudSyncMonitor.matchesRemoteChange(matching, storeURL: primaryStoreURL))
      XCTAssertFalse(CloudSyncMonitor.matchesRemoteChange(other, storeURL: primaryStoreURL))
      XCTAssertFalse(
        CloudSyncMonitor.matchesRemoteChange(
          Notification(name: .NSPersistentStoreRemoteChange),
          storeURL: primaryStoreURL
        )
      )
    }

    func testLocalSaveMatchesOnlyPrimaryContainerIdentity() throws {
      let directoryURL = try makeTemporaryDirectory()
      defer { try? FileManager.default.removeItem(at: directoryURL) }
      let primaryContainer = try WidgetSnapshotContainer.makeWriterContainer(
        at: directoryURL.appending(path: "primary.sqlite")
      )
      let snapshotContainer = try WidgetSnapshotContainer.makeWriterContainer(
        at: directoryURL.appending(path: "snapshot.sqlite")
      )
      let primarySave = Notification(
        name: ModelContext.didSave,
        object: ModelContext(primaryContainer)
      )
      let snapshotSave = Notification(
        name: ModelContext.didSave,
        object: ModelContext(snapshotContainer)
      )

      XCTAssertTrue(
        CloudSyncMonitor.matchesLocalSave(primarySave, primaryContainer: primaryContainer)
      )
      XCTAssertFalse(
        CloudSyncMonitor.matchesLocalSave(snapshotSave, primaryContainer: primaryContainer)
      )
      XCTAssertFalse(
        CloudSyncMonitor.matchesLocalSave(
          Notification(name: ModelContext.didSave),
          primaryContainer: primaryContainer
        )
      )
    }

    func testNotificationAdapterExtractsSendableSignalsOnPostingActor() async throws {
      let directoryURL = try makeTemporaryDirectory()
      let storeURL = directoryURL.appending(path: "primary.sqlite")
      let container = try WidgetSnapshotContainer.makeWriterContainer(at: storeURL)

      let signals = await NotificationAdapterProbe().extractSignals(
        container: container,
        storeURL: storeURL
      )

      XCTAssertEqual(signals.remoteStoreURL, storeURL)
      XCTAssertEqual(signals.containerIdentifier, ObjectIdentifier(container))
    }

    func testAttachPerformsOneRebuildForPrimaryRemoteChangeOnly() async throws {
      let directoryURL = try makeTemporaryDirectory()
      let primaryStoreURL = directoryURL.appending(path: "primary.sqlite")
      let primaryContainer = try WidgetSnapshotContainer.makeWriterContainer(
        at: primaryStoreURL
      )
      let builder = RuntimeBuilder()
      let writer = RuntimeWriter()
      let gate = ControlledDebounceGate()
      var reloadCount = 0
      let coordinator = WidgetSnapshotCoordinator(
        builder: builder,
        writer: writer,
        sleep: gate.sleep,
        reloadTimeline: {
          reloadCount += 1
        }
      )
      let acceptedRequest = expectation(description: "Primary remote change reaches coordinator")
      var acceptedRequestCount = 0
      var rebuildTasks = [Task<Void, Never>]()
      let monitor = CloudSyncMonitor(requestRebuild: { coordinator in
        let task = coordinator.requestRebuild()
        acceptedRequestCount += 1
        rebuildTasks.append(task)
        if acceptedRequestCount == 1 {
          acceptedRequest.fulfill()
        }
        return task
      })
      monitor.attach(primaryContainer: primaryContainer, coordinator: coordinator)
      defer { monitor.stop() }

      NotificationCenter.default.post(
        name: .NSPersistentStoreRemoteChange,
        object: nil,
        userInfo: [
          NSPersistentStoreURLKey: directoryURL.appending(path: "not-primary.sqlite"),
        ]
      )
      NotificationCenter.default.post(
        name: .NSPersistentStoreRemoteChange,
        object: nil,
        userInfo: [NSPersistentStoreURLKey: primaryStoreURL]
      )

      await fulfillment(of: [acceptedRequest], timeout: 5)
      monitor.stop()
      XCTAssertEqual(acceptedRequestCount, 1)
      XCTAssertEqual(rebuildTasks.count, 1)

      await gate.open()
      for task in rebuildTasks {
        await task.value
      }

      let replaceCount = await writer.replaceCount
      XCTAssertEqual(builder.buildCount, 1)
      XCTAssertEqual(replaceCount, 1)
      XCTAssertEqual(reloadCount, 1)
    }

    func testAttachIgnoresActorOwnedOtherContainerSave() async throws {
      let directoryURL = try makeTemporaryDirectory()
      let primaryStoreURL = directoryURL.appending(path: "primary.sqlite")
      let primaryContainer = try WidgetSnapshotContainer.makeWriterContainer(
        at: primaryStoreURL
      )
      let otherConfiguration = ModelConfiguration(
        schema: WidgetSnapshotContainer.schema,
        isStoredInMemoryOnly: true,
        cloudKitDatabase: .none
      )
      let otherContainer = try ModelContainer(
        for: WidgetSnapshotContainer.schema,
        configurations: [otherConfiguration]
      )
      let builder = RuntimeBuilder()
      let writer = RuntimeWriter()
      let gate = ControlledDebounceGate()
      var reloadCount = 0
      let coordinator = WidgetSnapshotCoordinator(
        builder: builder,
        writer: writer,
        sleep: gate.sleep,
        reloadTimeline: {
          reloadCount += 1
        }
      )
      var acceptedRequestCount = 0
      var rebuildTasks = [Task<Void, Never>]()
      let monitor = CloudSyncMonitor(requestRebuild: { coordinator in
        let task = coordinator.requestRebuild()
        acceptedRequestCount += 1
        rebuildTasks.append(task)
        return task
      })
      monitor.attach(primaryContainer: primaryContainer, coordinator: coordinator)
      defer { monitor.stop() }
      let saver = ModelContextSaver()

      let otherSaveExpectation = expectation(
        forNotification: ModelContext.didSave,
        object: nil
      ) { notification in
        CloudSyncNotificationAdapter.localSaveContainerIdentifier(from: notification)
          == ObjectIdentifier(otherContainer)
      }

      try await saver.saveParticipant(
        in: otherContainer,
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001").unsafelyUnwrapped
      )
      await fulfillment(of: [otherSaveExpectation], timeout: 5)
      monitor.stop()

      XCTAssertEqual(acceptedRequestCount, 0)
      XCTAssertTrue(rebuildTasks.isEmpty)
      await gate.open()

      let replaceCount = await writer.replaceCount
      XCTAssertEqual(builder.buildCount, 0)
      XCTAssertEqual(replaceCount, 0)
      XCTAssertEqual(reloadCount, 0)
    }

    func testAttachPerformsOneRebuildForActorOwnedPrimarySave() async throws {
      let directoryURL = try makeTemporaryDirectory()
      let primaryStoreURL = directoryURL.appending(path: "primary.sqlite")
      let primaryContainer = try WidgetSnapshotContainer.makeWriterContainer(
        at: primaryStoreURL
      )
      let builder = RuntimeBuilder()
      let writer = RuntimeWriter()
      let gate = ControlledDebounceGate()
      var reloadCount = 0
      let coordinator = WidgetSnapshotCoordinator(
        builder: builder,
        writer: writer,
        sleep: gate.sleep,
        reloadTimeline: {
          reloadCount += 1
        }
      )
      let acceptedRequests = expectation(description: "Primary save signals reach coordinator")
      acceptedRequests.expectedFulfillmentCount = 2
      var acceptedRequestCount = 0
      var rebuildTasks = [Task<Void, Never>]()
      let monitor = CloudSyncMonitor(requestRebuild: { coordinator in
        let task = coordinator.requestRebuild()
        acceptedRequestCount += 1
        rebuildTasks.append(task)
        if acceptedRequestCount <= 2 {
          acceptedRequests.fulfill()
        }
        return task
      })
      monitor.attach(primaryContainer: primaryContainer, coordinator: coordinator)
      defer { monitor.stop() }
      let saver = ModelContextSaver()

      let localSaveExpectation = expectation(
        forNotification: ModelContext.didSave,
        object: nil
      ) { notification in
        CloudSyncNotificationAdapter.localSaveContainerIdentifier(from: notification)
          == ObjectIdentifier(primaryContainer)
      }
      let remoteChangeExpectation = expectation(
        forNotification: .NSPersistentStoreRemoteChange,
        object: nil
      ) { notification in
        CloudSyncNotificationAdapter.remoteStoreURL(from: notification) == primaryStoreURL
      }

      try await saver.saveParticipant(
        in: primaryContainer,
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001").unsafelyUnwrapped
      )

      await fulfillment(
        of: [localSaveExpectation, remoteChangeExpectation, acceptedRequests],
        timeout: 5
      )
      monitor.stop()
      XCTAssertEqual(acceptedRequestCount, 2)
      XCTAssertEqual(rebuildTasks.count, 2)

      await gate.open()
      for task in rebuildTasks {
        await task.value
      }

      let replaceCount = await writer.replaceCount
      XCTAssertEqual(builder.buildCount, 1)
      XCTAssertEqual(replaceCount, 1)
      XCTAssertEqual(reloadCount, 1)
    }

    func testRuntimeStartsOnceInRequiredOrderAndRequestsOneInitialRebuild() throws {
      let directoryURL = try makeTemporaryDirectory()
      defer { try? FileManager.default.removeItem(at: directoryURL) }
      let primaryContainer = try WidgetSnapshotContainer.makeWriterContainer(
        at: directoryURL.appending(path: "primary.sqlite")
      )
      let operations = OperationLog()
      let coordinator = makeCoordinator()
      var eventObservationCount = 0
      var currentContainerRequestCount = 0
      var coordinatorFactoryCount = 0
      var attachCount = 0
      var attachedContainer: ModelContainer?
      var attachedCoordinator: WidgetSnapshotCoordinator?
      var requestRebuildCount = 0
      let runtime = CloudSyncRuntime(
        startEventObservation: {
          eventObservationCount += 1
          operations.append(.eventObservation)
        },
        currentContainer: {
          currentContainerRequestCount += 1
          operations.append(.currentContainer)
          return primaryContainer
        },
        makeCoordinator: { container in
          coordinatorFactoryCount += 1
          XCTAssertTrue(container === primaryContainer)
          operations.append(.makeCoordinator)
          return coordinator
        },
        attach: { container, coordinator in
          attachCount += 1
          attachedContainer = container
          attachedCoordinator = coordinator
          operations.append(.attach)
        },
        requestRebuild: { _ in
          requestRebuildCount += 1
          operations.append(.requestRebuild)
        }
      )

      runtime.start()
      runtime.start()

      XCTAssertEqual(eventObservationCount, 1)
      XCTAssertEqual(currentContainerRequestCount, 1)
      XCTAssertEqual(coordinatorFactoryCount, 1)
      XCTAssertEqual(attachCount, 1)
      XCTAssertTrue(attachedContainer === primaryContainer)
      XCTAssertTrue(attachedCoordinator === coordinator)
      XCTAssertEqual(requestRebuildCount, 1)
      XCTAssertEqual(
        operations.values,
        [.eventObservation, .currentContainer, .makeCoordinator, .attach, .requestRebuild]
      )
    }

    func testSnapshotInitializationFailureDoesNotEscapeOrRetryStartup() throws {
      let directoryURL = try makeTemporaryDirectory()
      defer { try? FileManager.default.removeItem(at: directoryURL) }
      let primaryContainer = try WidgetSnapshotContainer.makeWriterContainer(
        at: directoryURL.appending(path: "primary.sqlite")
      )
      let operations = OperationLog()
      var eventObservationCount = 0
      var coordinatorFactoryCount = 0
      var attachCount = 0
      var requestRebuildCount = 0
      let runtime = CloudSyncRuntime(
        startEventObservation: {
          eventObservationCount += 1
          operations.append(.eventObservation)
        },
        currentContainer: {
          operations.append(.currentContainer)
          return primaryContainer
        },
        makeCoordinator: { _ in
          coordinatorFactoryCount += 1
          operations.append(.makeCoordinator)
          throw TestError.snapshotInitialization
        },
        attach: { _, _ in
          attachCount += 1
          operations.append(.attach)
        },
        requestRebuild: { _ in
          requestRebuildCount += 1
          operations.append(.requestRebuild)
        }
      )

      runtime.start()
      runtime.start()

      XCTAssertEqual(eventObservationCount, 1)
      XCTAssertEqual(coordinatorFactoryCount, 1)
      XCTAssertEqual(attachCount, 0)
      XCTAssertEqual(requestRebuildCount, 0)
      XCTAssertEqual(
        operations.values,
        [.eventObservation, .currentContainer, .makeCoordinator]
      )
    }

    private func makeTemporaryDirectory() throws -> URL {
      let url = FileManager.default.temporaryDirectory.appending(
        path: "CloudSyncMonitorTests-\(UUID().uuidString)",
        directoryHint: .isDirectory
      )
      try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
      return url
    }

    private func makeCoordinator() -> WidgetSnapshotCoordinator {
      WidgetSnapshotCoordinator(
        builder: RuntimeBuilder(),
        writer: RuntimeWriter(),
        sleep: {},
        reloadTimeline: {}
      )
    }
  }

  @MainActor
  private final class RuntimeBuilder: WidgetSnapshotBuilding {
    private(set) var buildCount = 0

    func build() -> WidgetSnapshotValue {
      buildCount += 1
      return WidgetSnapshotValue(participants: [], moments: [])
    }
  }

  private actor RuntimeWriter: WidgetSnapshotWriting {
    private(set) var replaceCount = 0

    func replace(with _: WidgetSnapshotValue) {
      replaceCount += 1
    }
  }

  private actor ControlledDebounceGate {
    private var isOpen = false
    private var nextToken = 0
    private var waiters = [Int: CheckedContinuation<Void, any Error>]()

    func sleep() async throws {
      let token = nextToken
      nextToken += 1

      try await withTaskCancellationHandler {
        try await withCheckedThrowingContinuation { continuation in
          if isOpen {
            continuation.resume()
          }
          else {
            waiters[token] = continuation
          }
        }
      } onCancel: {
        Task { await self.cancel(token: token) }
      }
    }

    func open() {
      guard !isOpen else {
        return
      }
      isOpen = true
      let currentWaiters = Array(waiters.values)
      waiters.removeAll()
      for waiter in currentWaiters {
        waiter.resume()
      }
    }

    private func cancel(token: Int) {
      guard let continuation = waiters.removeValue(forKey: token) else {
        return
      }
      continuation.resume(throwing: CancellationError())
    }
  }

  private actor ModelContextSaver {
    func saveParticipant(in container: ModelContainer, id: UUID) throws {
      let context = ModelContext(container)
      context.insert(
        WidgetParticipantSnapshot(uuid: id, nickName: "Saved", avatarThumbnailData: nil)
      )
      try context.save()
    }
  }

  private actor NotificationAdapterProbe {
    func extractSignals(
      container: ModelContainer,
      storeURL: URL
    ) -> ExtractedNotificationSignals {
      let context = ModelContext(container)
      let remoteNotification = Notification(
        name: .NSPersistentStoreRemoteChange,
        userInfo: [NSPersistentStoreURLKey: storeURL]
      )
      let localNotification = Notification(name: ModelContext.didSave, object: context)

      return ExtractedNotificationSignals(
        remoteStoreURL: CloudSyncNotificationAdapter.remoteStoreURL(from: remoteNotification),
        containerIdentifier: CloudSyncNotificationAdapter.localSaveContainerIdentifier(
          from: localNotification
        )
      )
    }
  }

  // swiftformat:disable:next redundantSendable
  private struct ExtractedNotificationSignals: Sendable {
    let remoteStoreURL: URL?
    let containerIdentifier: ObjectIdentifier?
  }

  @MainActor
  private final class OperationLog {
    private(set) var values = [Operation]()

    func append(_ operation: Operation) {
      values.append(operation)
    }
  }

  private enum Operation: Equatable {
    case eventObservation
    case currentContainer
    case makeCoordinator
    case attach
    case requestRebuild
  }

  private enum TestError: Error {
    case snapshotInitialization
  }

#endif
