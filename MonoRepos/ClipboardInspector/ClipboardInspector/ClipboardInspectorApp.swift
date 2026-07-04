//
//  ClipboardInspectorApp.swift
//  ClipboardInspector
//
//  Created by tigerguo on 2023/3/16.
//

import HUIComponent
import SwiftUI

@main
struct ClipboardInspectorApp: App {
  @StateObject var settings = Settings.shared

  var body: some Scene {
    WindowGroup {
      HomeView()
        .environment(\.appLockEnabled, settings.pAppLockEnabled)
        .environmentObject(settings)
        .theme(settings.pTheme)
      #if os(iOS) || os(visionOS)
        .localAuth(
          needAuth: .constant(settings.pAppLockEnabled && HLocalAuth.canAuthWith(policy: .deviceOwnerAuthentication).isSuccess),
          localAuthConfig: AppConstants.localAuthConfig
        )
      #endif
    }
  }
}
