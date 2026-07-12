#if os(iOS)

  @testable import HDiaryAppFeature
  import CoreData
  import Foundation
  import HDiaryWidgetData
  import SwiftData
  import XCTest

  @MainActor
  final class CloudSyncMonitorTests: XCTestCase {
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
  private struct RuntimeBuilder: WidgetSnapshotBuilding {
    func build() -> WidgetSnapshotValue {
      WidgetSnapshotValue(participants: [], moments: [])
    }
  }

  private actor RuntimeWriter: WidgetSnapshotWriting {
    func replace(with _: WidgetSnapshotValue) {}
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
