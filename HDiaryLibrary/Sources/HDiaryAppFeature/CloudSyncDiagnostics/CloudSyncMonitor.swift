#if os(iOS)

  import Combine
  import CoreData
  import Foundation
  import HDiaryConstants
  import SwiftData

  nonisolated struct CloudSyncEventInput {
    let identifier: UUID
    let type: NSPersistentCloudKitContainer.EventType
    let startDate: Date
    let endDate: Date?
    let succeeded: Bool
    let error: (any Error)?
  }

  nonisolated enum CloudSyncNotificationAdapter {
    static func remoteStoreURL(from notification: Notification) -> URL? {
      notification.userInfo?[NSPersistentStoreURLKey] as? URL
    }

    static func localSaveContainerIdentifier(
      from notification: Notification
    ) -> ObjectIdentifier? {
      guard let context = notification.object as? ModelContext else {
        return nil
      }
      return ObjectIdentifier(context.container)
    }
  }

  // swiftformat:disable:next redundantSendable
  nonisolated struct PrimaryLocalSaveNotificationAdapter: Sendable {
    let primaryContainerIdentifier: ObjectIdentifier

    func callAsFunction(_ notification: Notification) -> ObjectIdentifier? {
      guard let containerIdentifier = CloudSyncNotificationAdapter.localSaveContainerIdentifier(
        from: notification
      ) else {
        return nil
      }
      guard containerIdentifier == primaryContainerIdentifier else {
        return nil
      }
      return containerIdentifier
    }
  }

  extension CloudSyncEventRecord {
    nonisolated init?(input: CloudSyncEventInput, now: Date = Date()) {
      let kind: Kind
      switch input.type {
      case .setup:
        kind = .setup
      case .import:
        kind = .importData
      case .export:
        kind = .export
      @unknown default:
        return nil
      }

      let state: State
      if input.endDate == nil {
        state = .inProgress
      }
      else if input.succeeded {
        state = .succeeded
      }
      else {
        state = .failed
      }

      self.init(
        id: input.identifier,
        storeIdentifier: "primary",
        kind: kind,
        startDate: input.startDate,
        endDate: input.endDate,
        state: state,
        error: input.error.flatMap { CloudSyncErrorDetails.from(error: $0, now: now) }
      )
    }

    @MainActor
    init?(event: NSPersistentCloudKitContainer.Event, now: Date = Date()) {
      self.init(
        input: CloudSyncEventInput(
          identifier: event.identifier,
          type: event.type,
          startDate: event.startDate,
          endDate: event.endDate,
          succeeded: event.succeeded,
          error: event.error
        ),
        now: now
      )
    }
  }

  @MainActor
  final class CloudSyncMonitor {
    let diagnosticsModel: CloudSyncDiagnosticsModel
    private let now: () -> Date
    private let requestRebuild: @MainActor (WidgetSnapshotCoordinator) -> Task<Void, Never>

    private var eventCancellables = Set<AnyCancellable>()
    private var attachmentCancellables = Set<AnyCancellable>()
    private var recordingTasks = [UUID: Task<Void, Never>]()

    init(
      diagnosticsModel: CloudSyncDiagnosticsModel = .shared,
      now: @escaping () -> Date = Date.init,
      requestRebuild: @escaping @MainActor (WidgetSnapshotCoordinator) -> Task<Void, Never> = {
        $0.requestRebuild()
      }
    ) {
      self.diagnosticsModel = diagnosticsModel
      self.now = now
      self.requestRebuild = requestRebuild
    }

    func startEventObservation() {
      guard eventCancellables.isEmpty else {
        return
      }

      NotificationCenter.default
        .publisher(for: NSPersistentCloudKitContainer.eventChangedNotification)
        .receive(on: RunLoop.main)
        .compactMap {
          $0.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
            as? NSPersistentCloudKitContainer.Event
        }
        .sink { [weak self] event in
          self?.record(event)
        }
        .store(in: &eventCancellables)
    }

    func attach(
      primaryContainer: ModelContainer,
      coordinator: WidgetSnapshotCoordinator
    ) {
      attachmentCancellables.removeAll()

      guard let primaryStoreURL = primaryContainer.configurations.first?.url else {
        Log.data.error("Failed to attach CloudKit change observers: primary store URL is missing")
        return
      }
      let primaryContainerIdentifier = ObjectIdentifier(primaryContainer)
      let primaryLocalSaveAdapter = PrimaryLocalSaveNotificationAdapter(
        primaryContainerIdentifier: primaryContainerIdentifier
      )

      NotificationCenter.default
        .publisher(for: .NSPersistentStoreRemoteChange)
        .compactMap(CloudSyncNotificationAdapter.remoteStoreURL(from:))
        .receive(on: RunLoop.main)
        .filter { $0 == primaryStoreURL }
        .sink { [weak self, weak coordinator] _ in
          guard let self, let coordinator else {
            return
          }
          _ = self.requestRebuild(coordinator)
        }
        .store(in: &attachmentCancellables)

      NotificationCenter.default
        .publisher(for: ModelContext.didSave)
        .compactMap(primaryLocalSaveAdapter.callAsFunction)
        .receive(on: RunLoop.main)
        .sink { [weak self, weak coordinator] _ in
          guard let self, let coordinator else {
            return
          }
          _ = self.requestRebuild(coordinator)
        }
        .store(in: &attachmentCancellables)
    }

    func stop() {
      eventCancellables.removeAll()
      attachmentCancellables.removeAll()
      recordingTasks.values.forEach { $0.cancel() }
      recordingTasks.removeAll()
    }

    static func matchesRemoteChange(
      _ notification: Notification,
      storeURL: URL
    ) -> Bool {
      CloudSyncNotificationAdapter.remoteStoreURL(from: notification) == storeURL
    }

    static func matchesLocalSave(
      _ notification: Notification,
      primaryContainer: ModelContainer
    ) -> Bool {
      CloudSyncNotificationAdapter.localSaveContainerIdentifier(from: notification)
        == ObjectIdentifier(primaryContainer)
    }

    private func record(_ event: NSPersistentCloudKitContainer.Event) {
      guard let record = CloudSyncEventRecord(event: event, now: now()) else {
        Log.data.error("Ignored an unknown CloudKit sync event type")
        return
      }

      Log.data.info(
        "CloudKit sync event \(record.kind.rawValue) is \(record.state.rawValue)"
      )

      let taskIdentifier = UUID()
      let diagnosticsModel = diagnosticsModel
      let task = Task { @MainActor [weak self, diagnosticsModel] in
        await diagnosticsModel.record(record)
        self?.recordingTasks[taskIdentifier] = nil
      }
      recordingTasks[taskIdentifier] = task
    }

    isolated deinit {
      stop()
    }
  }

#endif
