//
//  AppStoreArtWorkApp.swift
//  AppStoreArtWork
//
//  Created by tigerguo on 2025/3/19.
//

import SwiftUI

@main
struct AppStoreArtWorkApp: App {
  @State var store = Store()
  var body: some Scene {
    WindowGroup {
      ContentView()
    }
    .environment(store)
    .environment(Route())
    .commands(content: {
      CommandGroup(replacing: .newItem) {
        Button("Import ...") {
          Task {
            await importStore()
          }
        }
        .keyboardShortcut("I", modifiers: [.command, .shift])

        Button("导出当前设置") {
          PersistUtil().export(store)
        }
        .keyboardShortcut("E", modifiers: [.command, .shift])
        Button("导出上架图") {
          Task {
            try await ExportArtImageUtil.export(store: store)
          }
        }
      }
    }
    )
  }

  private func importStore() async {
    do {
      if let loadedStore = try await PersistUtil().importStore() {
        Log.data.info("Updating store from file")
        store = loadedStore
      }
      else {
        Log.data.error("No store loaded")
      }
    }
    catch {
      Log.data.error("Load store from data failed with error \(error)")
    }
  }
}
