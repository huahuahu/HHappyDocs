#if os(iOS)

  @testable import HDiaryAppFeature
  import CoreData
  import Foundation
  import HDiaryWidgetData
  import SwiftData
  import XCTest

  @MainActor
  final class WidgetSnapshotChangeMonitorTests: XCTestCase {
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

      XCTAssertTrue(WidgetSnapshotChangeMonitor.matchesRemoteChange(matching, storeURL: primaryStoreURL))
      XCTAssertFalse(WidgetSnapshotChangeMonitor.matchesRemoteChange(other, storeURL: primaryStoreURL))
      XCTAssertFalse(
        WidgetSnapshotChangeMonitor.matchesRemoteChange(
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
        WidgetSnapshotChangeMonitor.matchesLocalSave(primarySave, primaryContainer: primaryContainer)
      )
      XCTAssertFalse(
        WidgetSnapshotChangeMonitor.matchesLocalSave(snapshotSave, primaryContainer: primaryContainer)
      )
      XCTAssertFalse(
        WidgetSnapshotChangeMonitor.matchesLocalSave(
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
      let monitor = WidgetSnapshotChangeMonitor(requestRebuild: { coordinator in
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
      let buildCount = await builder.buildCount
      XCTAssertEqual(buildCount, 1)
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
      let monitor = WidgetSnapshotChangeMonitor(requestRebuild: { coordinator in
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
        WidgetSnapshotNotificationAdapter.localSaveContainerIdentifier(from: notification)
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
      let buildCount = await builder.buildCount
      XCTAssertEqual(buildCount, 0)
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
      let monitor = WidgetSnapshotChangeMonitor(requestRebuild: { coordinator in
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
        WidgetSnapshotNotificationAdapter.localSaveContainerIdentifier(from: notification)
          == ObjectIdentifier(primaryContainer)
      }
      let remoteChangeExpectation = expectation(
        forNotification: .NSPersistentStoreRemoteChange,
        object: nil
      ) { notification in
        WidgetSnapshotNotificationAdapter.remoteStoreURL(from: notification) == primaryStoreURL
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
      let buildCount = await builder.buildCount
      XCTAssertEqual(buildCount, 1)
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
      var currentContainerRequestCount = 0
      var coordinatorFactoryCount = 0
      var attachCount = 0
      var attachedContainer: ModelContainer?
      var attachedCoordinator: WidgetSnapshotCoordinator?
      var requestRebuildCount = 0
      let runtime = WidgetSnapshotRuntime(
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

      XCTAssertEqual(currentContainerRequestCount, 1)
      XCTAssertEqual(coordinatorFactoryCount, 1)
      XCTAssertEqual(attachCount, 1)
      XCTAssertTrue(attachedContainer === primaryContainer)
      XCTAssertTrue(attachedCoordinator === coordinator)
      XCTAssertEqual(requestRebuildCount, 1)
      XCTAssertEqual(
        operations.values,
        [.currentContainer, .makeCoordinator, .attach, .requestRebuild]
      )
    }

    func testSnapshotInitializationFailureDoesNotEscapeOrRetryStartup() throws {
      let directoryURL = try makeTemporaryDirectory()
      defer { try? FileManager.default.removeItem(at: directoryURL) }
      let primaryContainer = try WidgetSnapshotContainer.makeWriterContainer(
        at: directoryURL.appending(path: "primary.sqlite")
      )
      let operations = OperationLog()
      var coordinatorFactoryCount = 0
      var attachCount = 0
      var requestRebuildCount = 0
      let runtime = WidgetSnapshotRuntime(
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

      XCTAssertEqual(coordinatorFactoryCount, 1)
      XCTAssertEqual(attachCount, 0)
      XCTAssertEqual(requestRebuildCount, 0)
      XCTAssertEqual(
        operations.values,
        [.currentContainer, .makeCoordinator]
      )
    }

    private func makeTemporaryDirectory() throws -> URL {
      let url = FileManager.default.temporaryDirectory.appending(
        path: "WidgetSnapshotChangeMonitorTests-\(UUID().uuidString)",
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

  private actor RuntimeBuilder: WidgetSnapshotBuilding {
    private(set) var buildCount = 0

    func build() -> WidgetSnapshotValue {
      buildCount += 1
      return WidgetSnapshotValue(participants: [], moments: [])
    }
  }

  private actor RuntimeWriter: WidgetSnapshotWriting {
    private(set) var replaceCount = 0

    func replace(with _: WidgetSnapshotValue) -> Bool {
      replaceCount += 1
      return true
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
        remoteStoreURL: WidgetSnapshotNotificationAdapter.remoteStoreURL(from: remoteNotification),
        containerIdentifier: WidgetSnapshotNotificationAdapter.localSaveContainerIdentifier(
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
    case currentContainer
    case makeCoordinator
    case attach
    case requestRebuild
  }

  private enum TestError: Error {
    case snapshotInitialization
  }

#endif
