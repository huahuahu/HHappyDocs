#if os(iOS)

  import HDiaryConstants
  import HDiaryWidgetData
  import WidgetKit

  /// 定义可跨并发域生成 Widget 快照的能力。
  nonisolated protocol WidgetSnapshotBuilding: Sendable {
    func build() async throws -> WidgetSnapshotValue
  }

  /// 定义持久化快照并报告内容是否变化的能力。
  nonisolated protocol WidgetSnapshotWriting: Sendable {
    func replace(with snapshot: WidgetSnapshotValue) async throws -> Bool
  }

  extension WidgetSnapshotStore: WidgetSnapshotWriting {}

  /// 合并密集的更新请求，并串行完成生成、写入与 timeline 刷新。
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
      if debounceTask != nil {
        Log.Widget.snapshot.log(
          level: DiagnosticLogging.level(for: .debug),
          "Coalescing pending widget snapshot rebuild request"
        )
      }
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
          Log.Widget.snapshot.error("Failed to debounce widget snapshot rebuild: \(error)")
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
        Log.Widget.snapshot.log(
          level: DiagnosticLogging.level(for: .debug),
          "Queued follow-up widget snapshot rebuild"
        )
        return
      }

      isRebuilding = true
      defer { isRebuilding = false }

      repeat {
        needsAnotherRebuild = false
        await rebuildSnapshot()
      }
      while needsAnotherRebuild
    }

    private func rebuildSnapshot() async {
      let start = ContinuousClock.now
      Log.Widget.snapshot.log(
        level: DiagnosticLogging.level(for: .debug),
        "Widget snapshot rebuild started"
      )
      do {
        let snapshot = try await builder.build()
        let didChange = try await writer.replace(with: snapshot)
        if didChange {
          reloadTimeline()
        }
        let duration = start.duration(to: .now)
        Log.Widget.snapshot.log(
          level: DiagnosticLogging.level(for: .info),
          "Widget snapshot rebuild finished: participants=\(snapshot.participants.count, privacy: .public), moments=\(snapshot.moments.count, privacy: .public), changed=\(didChange, privacy: .public), duration=\(duration, privacy: .public)"
        )
      }
      catch {
        Log.Widget.snapshot.error("Failed to rebuild widget snapshot: \(error)")
      }
    }

    isolated deinit {
      debounceTask?.cancel()
    }
  }

#endif
