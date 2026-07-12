#if os(iOS)

  import HDiaryConstants
  import HDiaryModel
  import HDiaryWidgetData
  import SwiftData

  @MainActor
  final class CloudSyncRuntime {
    static let shared: CloudSyncRuntime = {
      let monitor = CloudSyncMonitor()
      return CloudSyncRuntime(
        startEventObservation: monitor.startEventObservation,
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

    private let startEventObservation: @MainActor () -> Void
    private let currentContainer: @MainActor () -> ModelContainer
    private let makeCoordinator: @MainActor (ModelContainer) throws -> WidgetSnapshotCoordinator
    private let attach: @MainActor (ModelContainer, WidgetSnapshotCoordinator) -> Void
    private let requestRebuild: @MainActor (WidgetSnapshotCoordinator) -> Void

    private var hasStarted = false
    private var coordinator: WidgetSnapshotCoordinator?

    init(
      startEventObservation: @escaping @MainActor () -> Void,
      currentContainer: @escaping @MainActor () -> ModelContainer,
      makeCoordinator: @escaping @MainActor (ModelContainer) throws -> WidgetSnapshotCoordinator,
      attach: @escaping @MainActor (ModelContainer, WidgetSnapshotCoordinator) -> Void,
      requestRebuild: @escaping @MainActor (WidgetSnapshotCoordinator) -> Void
    ) {
      self.startEventObservation = startEventObservation
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

      startEventObservation()
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
