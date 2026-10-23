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
      #if DEBUG
        if AppStoreScreenshotFixture.active != nil || MomentMediaPreviewFixture.active != nil || AvatarEditingValidationView.isEnabled {
          return
        }
      #endif
      WidgetSnapshotSyncRuntime.shared.start(
        primaryContainer: HDiaryContainer.currentContainer
      )
    }

    public var body: some Scene {
      WindowGroup {
        #if DEBUG
          if AvatarEditingValidationView.isEnabled {
            AvatarEditingValidationView()
          }
          else if let fixture = MomentMediaPreviewFixture.active {
            MomentDetailPreview(fixture: fixture)
          }
          else if let fixture = AppStoreScreenshotFixture.active {
            AppStoreScreenshotView(fixture: fixture)
          }
          else {
            appContent
          }
        #else
          appContent
        #endif
      }
    }

    private var appContent: some View {
      BaseTabView()
        .withEnvironments()
        .withModelContainer()
    }
  }

#endif
