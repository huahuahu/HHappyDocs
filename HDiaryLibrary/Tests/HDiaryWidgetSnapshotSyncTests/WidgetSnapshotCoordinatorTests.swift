#if os(iOS)

  @testable import HDiaryWidgetSnapshotSync
  import Foundation
  import HDiaryWidgetData
  import XCTest

  @MainActor
  final class WidgetSnapshotCoordinatorTests: XCTestCase {
    func testSuccessfulRebuildWritesThenReloadsTimeline() async {
      let builder = BuilderSpy(result: .success(.fixture))
      let writer = WriterSpy()
      let reloader = ReloaderSpy()
      let coordinator = WidgetSnapshotCoordinator(
        builder: builder,
        writer: writer,
        sleep: {},
        reloadTimeline: reloader.reload
      )

      await coordinator.rebuildNow()

      let snapshots = await writer.snapshots
      XCTAssertEqual(snapshots, [.fixture])
      XCTAssertEqual(reloader.reloadCount, 1)
    }

    func testTimelineDoesNotReloadUntilWriteCompletes() async {
      let builder = BuilderSpy(result: .success(.fixture))
      let writer = PausingWriterSpy()
      let reloader = ReloaderSpy()
      let coordinator = WidgetSnapshotCoordinator(
        builder: builder,
        writer: writer,
        sleep: {},
        reloadTimeline: reloader.reload
      )

      let rebuild = Task { await coordinator.rebuildNow() }
      await writer.waitUntilFirstWriteIsPaused()

      let snapshotsWhileWriting = await writer.snapshots
      XCTAssertTrue(snapshotsWhileWriting.isEmpty)
      XCTAssertEqual(reloader.reloadCount, 0)

      await writer.releaseFirstWrite()
      await rebuild.value

      let snapshots = await writer.snapshots
      XCTAssertEqual(snapshots, [.fixture])
      XCTAssertEqual(reloader.reloadCount, 1)
    }

    func testBuildFailureDoesNotWriteOrReloadTimeline() async {
      let builder = BuilderSpy(result: .failure(.build))
      let writer = WriterSpy()
      let reloader = ReloaderSpy()
      let coordinator = WidgetSnapshotCoordinator(
        builder: builder,
        writer: writer,
        sleep: {},
        reloadTimeline: reloader.reload
      )

      await coordinator.rebuildNow()

      let snapshots = await writer.snapshots
      XCTAssertTrue(snapshots.isEmpty)
      XCTAssertEqual(reloader.reloadCount, 0)
    }

    func testWriteFailureKeepsPreviousSnapshotAndDoesNotReload() async {
      let builder = BuilderSpy(result: .success(.fixture))
      let writer = WriterSpy(error: .write)
      let reloader = ReloaderSpy()
      let coordinator = WidgetSnapshotCoordinator(
        builder: builder,
        writer: writer,
        sleep: {},
        reloadTimeline: reloader.reload
      )

      await coordinator.rebuildNow()

      let snapshots = await writer.snapshots
      XCTAssertTrue(snapshots.isEmpty)
      XCTAssertEqual(reloader.reloadCount, 0)
    }

    func testTwoPendingRequestsCoalesceIntoOneRebuild() async {
      let builder = BuilderSpy(result: .success(.fixture))
      let writer = WriterSpy()
      let reloader = ReloaderSpy()
      let sleeper = ControlledDebounceSleeper()
      let coordinator = WidgetSnapshotCoordinator(
        builder: builder,
        writer: writer,
        sleep: sleeper.sleep,
        reloadTimeline: reloader.reload
      )

      let first = coordinator.requestRebuild()
      await sleeper.waitUntilSleeping()
      let second = coordinator.requestRebuild()
      await sleeper.waitUntilSleeping()
      await sleeper.releaseCurrentWaiter()
      await first.value
      await second.value

      let buildCount = await builder.buildCount
      XCTAssertEqual(buildCount, 1)
      let snapshots = await writer.snapshots
      XCTAssertEqual(snapshots, [.fixture])
      XCTAssertEqual(reloader.reloadCount, 1)
    }

    func testRequestDuringRebuildRunsOneSerializedFollowUpWithLatestState() async {
      let builder = BuilderSpy(result: .success(.fixture))
      let writer = PausingWriterSpy()
      let reloader = ReloaderSpy()
      let sleeper = ControlledDebounceSleeper()
      let coordinator = WidgetSnapshotCoordinator(
        builder: builder,
        writer: writer,
        sleep: sleeper.sleep,
        reloadTimeline: reloader.reload
      )

      let initial = coordinator.requestRebuild()
      await sleeper.waitUntilSleeping()
      await sleeper.releaseCurrentWaiter()
      await writer.waitUntilFirstWriteIsPaused()

      await builder.setResult(.success(.latestFixture))
      let followUp = coordinator.requestRebuild()
      await sleeper.waitUntilSleeping()
      await sleeper.releaseCurrentWaiter()
      await followUp.value

      let pausedBuildCount = await builder.buildCount
      XCTAssertEqual(pausedBuildCount, 1)

      await writer.releaseFirstWrite()
      await initial.value

      let completedBuildCount = await builder.buildCount
      XCTAssertEqual(completedBuildCount, 2)
      let snapshots = await writer.snapshots
      let maximumConcurrentWriteCount = await writer.maximumConcurrentWriteCount
      XCTAssertEqual(snapshots, [.fixture, .latestFixture])
      XCTAssertEqual(maximumConcurrentWriteCount, 1)
      XCTAssertEqual(reloader.reloadCount, 2)
    }
  }

  private enum TestError: Error {
    case build
    case write
  }

  private actor BuilderSpy: WidgetSnapshotBuilding {
    private(set) var buildCount = 0
    private var result: Result<WidgetSnapshotValue, TestError>

    init(result: Result<WidgetSnapshotValue, TestError>) {
      self.result = result
    }

    func build() async throws -> WidgetSnapshotValue {
      buildCount += 1
      return try result.get()
    }

    func setResult(_ result: Result<WidgetSnapshotValue, TestError>) {
      self.result = result
    }
  }

  private actor WriterSpy: WidgetSnapshotWriting {
    private(set) var snapshots = [WidgetSnapshotValue]()
    var error: TestError?

    init(error: TestError? = nil) {
      self.error = error
    }

    func replace(with snapshot: WidgetSnapshotValue) throws -> Bool {
      if let error {
        throw error
      }
      snapshots.append(snapshot)
      return true
    }
  }

  @MainActor
  private final class ReloaderSpy {
    private(set) var reloadCount = 0

    func reload() {
      reloadCount += 1
    }
  }

  private actor PausingWriterSpy: WidgetSnapshotWriting {
    private(set) var snapshots = [WidgetSnapshotValue]()
    private(set) var maximumConcurrentWriteCount = 0
    private var replaceCount = 0
    private var concurrentWriteCount = 0
    private var firstWriteContinuation: CheckedContinuation<Void, Never>?
    private var firstWriteObservers = [CheckedContinuation<Void, Never>]()
    private var isFirstWritePaused = false

    func replace(with snapshot: WidgetSnapshotValue) async throws -> Bool {
      replaceCount += 1
      concurrentWriteCount += 1
      maximumConcurrentWriteCount = max(maximumConcurrentWriteCount, concurrentWriteCount)
      defer { concurrentWriteCount -= 1 }

      if replaceCount == 1 {
        await withCheckedContinuation { continuation in
          firstWriteContinuation = continuation
          isFirstWritePaused = true
          let observers = firstWriteObservers
          firstWriteObservers.removeAll()
          for observer in observers {
            observer.resume()
          }
        }
      }

      try Task.checkCancellation()
      snapshots.append(snapshot)
      return true
    }

    func waitUntilFirstWriteIsPaused() async {
      if isFirstWritePaused {
        return
      }

      await withCheckedContinuation { continuation in
        firstWriteObservers.append(continuation)
      }
    }

    func releaseFirstWrite() {
      guard let continuation = firstWriteContinuation else {
        return
      }
      firstWriteContinuation = nil
      continuation.resume()
    }
  }

  private actor ControlledDebounceSleeper {
    private struct SleepObserver {
      let minimumToken: Int
      let continuation: CheckedContinuation<Void, Never>
    }

    private var nextToken = 0
    private var lastObservedToken = -1
    private var waiters = [Int: CheckedContinuation<Void, any Error>]()
    private var sleepObservers = [SleepObserver]()

    func sleep() async throws {
      let token = nextToken
      nextToken += 1

      try await withTaskCancellationHandler {
        try await withCheckedThrowingContinuation { continuation in
          waiters[token] = continuation
          let observers = sleepObservers.filter { token > $0.minimumToken }
          sleepObservers.removeAll { token > $0.minimumToken }
          if !observers.isEmpty {
            lastObservedToken = max(lastObservedToken, token)
          }
          for observer in observers {
            observer.continuation.resume()
          }
        }
      } onCancel: {
        Task { await self.cancel(token: token) }
      }
    }

    func waitUntilSleeping() async {
      if let currentToken = waiters.keys.max(), currentToken > lastObservedToken {
        lastObservedToken = currentToken
        return
      }

      let minimumToken = lastObservedToken
      await withCheckedContinuation { continuation in
        sleepObservers.append(
          SleepObserver(minimumToken: minimumToken, continuation: continuation)
        )
      }
    }

    func releaseCurrentWaiter() {
      guard let token = waiters.keys.max(),
            let continuation = waiters.removeValue(forKey: token)
      else {
        return
      }
      continuation.resume()
    }

    private func cancel(token: Int) {
      guard let continuation = waiters.removeValue(forKey: token) else {
        return
      }
      continuation.resume(throwing: CancellationError())
    }
  }

  private extension WidgetSnapshotValue {
    static let fixture = WidgetSnapshotValue(participants: [], moments: [])

    static let latestFixture = WidgetSnapshotValue(
      participants: [
        WidgetParticipantValue(
          uuid: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
          nickName: "Latest",
          avatarThumbnailData: nil
        ),
      ],
      moments: []
    )
  }

#endif
