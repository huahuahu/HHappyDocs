#if os(iOS)

  import HDiaryConstants
  import HDiaryModel
  import HDiaryWidgetData
  import SwiftData

  /// 在主 App 启动时组装快照组件、注册监听并触发初次重建。
  @MainActor
  final class WidgetSnapshotRuntime {
    static let shared: WidgetSnapshotRuntime = {
      let monitor = WidgetSnapshotChangeMonitor()
      return WidgetSnapshotRuntime(
        currentContainer: { HDiaryContainer.currentContainer },
        makeCoordinator: { primaryContainer in
          let writerContainer = try WidgetSnapshotContainer.makeWriterContainer()
          let writer = WidgetSnapshotStore(modelContainer: writerContainer)
          let builder = MainStoreWidgetSnapshotBuilder(container: primaryContainer)
          return WidgetSnapshotCoordinator(builder: builder, writer: writer)
        },
        attach: monitor.attach,
        requestRebuild: { coordinator in
          _ = coordinator.requestRebuild()
        }
      )
    }()

    private let currentContainer: @MainActor () -> ModelContainer
    private let makeCoordinator: @MainActor (ModelContainer) throws -> WidgetSnapshotCoordinator
    private let attach: @MainActor (ModelContainer, WidgetSnapshotCoordinator) -> Void
    private let requestRebuild: @MainActor (WidgetSnapshotCoordinator) -> Void

    private var hasStarted = false
    private var coordinator: WidgetSnapshotCoordinator?

    init(
      currentContainer: @escaping @MainActor () -> ModelContainer,
      makeCoordinator: @escaping @MainActor (ModelContainer) throws -> WidgetSnapshotCoordinator,
      attach: @escaping @MainActor (ModelContainer, WidgetSnapshotCoordinator) -> Void,
      requestRebuild: @escaping @MainActor (WidgetSnapshotCoordinator) -> Void
    ) {
      self.currentContainer = currentContainer
      self.makeCoordinator = makeCoordinator
      self.attach = attach
      self.requestRebuild = requestRebuild
    }

    func start() {
      guard !hasStarted else {
        return
      }
      hasStarted = true

      let primaryContainer = currentContainer()

      do {
        let coordinator = try makeCoordinator(primaryContainer)
        self.coordinator = coordinator
        attach(primaryContainer, coordinator)
        requestRebuild(coordinator)
      }
      catch {
        Log.data.error("Failed to initialize widget snapshot runtime: \(error.localizedDescription)")
      }
    }
  }

#endif
