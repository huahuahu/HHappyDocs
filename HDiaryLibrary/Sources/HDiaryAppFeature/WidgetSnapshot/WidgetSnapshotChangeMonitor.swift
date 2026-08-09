#if os(iOS)

  import Combine
  import CoreData
  import Foundation
  import HDiaryConstants
  import SwiftData

  /// 从持久化通知中提取可安全比较的 Store 与容器标识。
  nonisolated enum WidgetSnapshotNotificationAdapter {
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

  /// 只允许主 Store 的本地保存通知触发快照更新。
  // swiftformat:disable:next redundantSendable
  nonisolated struct PrimaryLocalSaveNotificationAdapter: Sendable {
    let primaryContainerIdentifier: ObjectIdentifier

    func callAsFunction(_ notification: Notification) -> ObjectIdentifier? {
      guard let containerIdentifier = WidgetSnapshotNotificationAdapter
        .localSaveContainerIdentifier(from: notification)
      else {
        return nil
      }
      guard containerIdentifier == primaryContainerIdentifier else {
        return nil
      }
      return containerIdentifier
    }
  }

  /// 监听主 Store 的本地保存与远端变更，并请求重建 Widget 快照。
  @MainActor
  final class WidgetSnapshotChangeMonitor {
    private let requestRebuild: @MainActor (WidgetSnapshotCoordinator) -> Task<Void, Never>
    private var cancellables = Set<AnyCancellable>()

    init(
      requestRebuild: @escaping @MainActor (WidgetSnapshotCoordinator) -> Task<Void, Never> = {
        $0.requestRebuild()
      }
    ) {
      self.requestRebuild = requestRebuild
    }

    func attach(
      primaryContainer: ModelContainer,
      coordinator: WidgetSnapshotCoordinator
    ) {
      cancellables.removeAll()

      guard let primaryStoreURL = primaryContainer.configurations.first?.url else {
        Log.data.error("Failed to attach widget snapshot observers: primary store URL is missing")
        return
      }
      let primaryLocalSaveAdapter = PrimaryLocalSaveNotificationAdapter(
        primaryContainerIdentifier: ObjectIdentifier(primaryContainer)
      )

      NotificationCenter.default
        .publisher(for: .NSPersistentStoreRemoteChange)
        .compactMap(WidgetSnapshotNotificationAdapter.remoteStoreURL(from:))
        .receive(on: RunLoop.main)
        .filter { $0 == primaryStoreURL }
        .sink { [weak self, weak coordinator] _ in
          guard let self, let coordinator else {
            return
          }
          _ = self.requestRebuild(coordinator)
        }
        .store(in: &cancellables)

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
        .store(in: &cancellables)
    }

    func stop() {
      cancellables.removeAll()
    }

    static func matchesRemoteChange(
      _ notification: Notification,
      storeURL: URL
    ) -> Bool {
      WidgetSnapshotNotificationAdapter.remoteStoreURL(from: notification) == storeURL
    }

    static func matchesLocalSave(
      _ notification: Notification,
      primaryContainer: ModelContainer
    ) -> Bool {
      WidgetSnapshotNotificationAdapter.localSaveContainerIdentifier(from: notification)
        == ObjectIdentifier(primaryContainer)
    }

    isolated deinit {
      stop()
    }
  }

#endif
