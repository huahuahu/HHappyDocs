//
//  ExifViewerApp.swift
//  ExifViewer
//
//  Created by tigerguo on 2025/3/7.
//

import SwiftUI

@main
struct ExifViewerApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environment(\.supportEdit, false)
    }
  }
}
