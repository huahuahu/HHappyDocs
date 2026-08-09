//
//  HDiaryApp.swift
//  HDiary
//
//  Created by tigerguo on 2023/6/17.
//

#if os(iOS)

  import HDiaryModel
  import HDiaryWidgetSnapshotSync
  import SwiftData
  import SwiftUI

  public struct HDiaryFeatureApp: App {
    public init() {
      WidgetSnapshotSyncRuntime.shared.start(
        primaryContainer: HDiaryContainer.currentContainer
      )
    }

    public var body: some Scene {
      WindowGroup {
        BaseTabView()
          .withEnvironments()
          .withModelContainer()
      }
    }
  }

#endif
