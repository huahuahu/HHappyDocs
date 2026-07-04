//
//  ExifEditorApp.swift
//  ExifEditor
//
//  Created by tigerguo on 2025/3/7.
//

import SharedExifPackage
import SwiftUI

@main
struct ExifEditorApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environment(\.supportEdit, true)
    }
  }
}
