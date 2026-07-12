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

    private var eventCancellables = Set<AnyCancellable>()
    private var attachmentCancellables = Set<AnyCancellable>()
    private var recordingTasks = [UUID: Task<Void, Never>]()

    init(
      diagnosticsModel: CloudSyncDiagnosticsModel = .shared,
      now: @escaping () -> Date = Date.init
    ) {
      self.diagnosticsModel = diagnosticsModel
      self.now = now
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

      NotificationCenter.default
        .publisher(for: .NSPersistentStoreRemoteChange)
        .receive(on: RunLoop.main)
        .filter {
          Self.matchesRemoteChange($0, storeURL: primaryStoreURL)
        }
        .sink { [weak coordinator] _ in
          _ = coordinator?.requestRebuild()
        }
        .store(in: &attachmentCancellables)

      NotificationCenter.default
        .publisher(for: ModelContext.didSave)
        .receive(on: RunLoop.main)
        .filter {
          Self.matchesLocalSave($0, primaryContainer: primaryContainer)
        }
        .sink { [weak coordinator] _ in
          _ = coordinator?.requestRebuild()
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
      notification.userInfo?[NSPersistentStoreURLKey] as? URL == storeURL
    }

    static func matchesLocalSave(
      _ notification: Notification,
      primaryContainer: ModelContainer
    ) -> Bool {
      guard let context = notification.object as? ModelContext else {
        return false
      }
      return context.container === primaryContainer
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
