#if os(iOS)

  import HDiaryConstants
  import HDiaryWidgetData
  import WidgetKit

  @MainActor
  protocol WidgetSnapshotBuilding {
    func build() async throws -> WidgetSnapshotValue
  }

  protocol WidgetSnapshotWriting: Sendable {
    func replace(with snapshot: WidgetSnapshotValue) async throws -> Bool
  }

  extension WidgetSnapshotStore: WidgetSnapshotWriting {}

  @MainActor
  final class WidgetSnapshotCoordinator {
    private let builder: any WidgetSnapshotBuilding
    private let writer: any WidgetSnapshotWriting
    private let sleep: @Sendable () async throws -> Void
    private let reloadTimeline: @MainActor () -> Void

    private var debounceTask: Task<Void, Never>?
    private var isRebuilding = false
    private var needsAnotherRebuild = false

    init(
      builder: any WidgetSnapshotBuilding,
      writer: any WidgetSnapshotWriting,
      sleep: @escaping @Sendable () async throws -> Void = {
        try await Task.sleep(for: .milliseconds(350))
      },
      reloadTimeline: @escaping @MainActor () -> Void = {
        WidgetCenter.shared.reloadTimelines(ofKind: HDiaryIntentKind.moment.rawValue)
      }
    ) {
      self.builder = builder
      self.writer = writer
      self.sleep = sleep
      self.reloadTimeline = reloadTimeline
    }

    func requestRebuild() -> Task<Void, Never> {
      debounceTask?.cancel()
      let sleep = self.sleep
      let task = Task { @MainActor [weak self, sleep] in
        do {
          try await sleep()
          try Task.checkCancellation()
        }
        catch is CancellationError {
          return
        }
        catch {
          Log.data.error("Failed to debounce widget snapshot rebuild: \(error)")
          return
        }

        guard let self else {
          return
        }
        debounceTask = nil
        await runRebuildLoop()
      }
      debounceTask = task
      return task
    }

    func rebuildNow() async {
      await runRebuildLoop()
    }

    private func runRebuildLoop() async {
      if isRebuilding {
        needsAnotherRebuild = true
        return
      }

      isRebuilding = true
      defer { isRebuilding = false }

      repeat {
        needsAnotherRebuild = false
        await rebuildSnapshot()
      } while needsAnotherRebuild
    }

    private func rebuildSnapshot() async {
      do {
        let snapshot = try await builder.build()
        let didChange = try await writer.replace(with: snapshot)
        if didChange {
          reloadTimeline()
        }
      }
      catch {
        Log.data.error("Failed to rebuild widget snapshot: \(error)")
      }
    }

    isolated deinit {
      debounceTask?.cancel()
    }
  }

#endif
