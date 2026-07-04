//
//  PersistUtil.swift
//  AppStoreArtWork
//
//  Created by tigerguo on 2025/3/21.
//

import AppKit
import Foundation

@MainActor
struct PersistUtil {
  func importStore() async throws -> Store? {
    Log.data.info("Importing store")

    let openPanel = NSOpenPanel()
    openPanel.allowedContentTypes = [.json]
    openPanel.allowsMultipleSelection = false
    let response = await openPanel.beginSheetModal(for: NSApp.keyWindow!)

    guard response == .OK,
          let url = openPanel.url else {
      Log.data.info("Import cancelled")
      return nil
    }

    let data = try Data(contentsOf: url)
    let store = try Store.fromData(data)
    Log.data.info("Successfully imported store from \(url.lastPathComponent)")
    // 这里需要处理store对象，例如更新应用状态
    return store
  }

  func export(_ store: Store) {
    Log.data.info("Exporting store")

    let savePanel = NSSavePanel()
    savePanel.allowedContentTypes = [.json]
    savePanel.nameFieldStringValue = "Artwork_exported.json"

    do {
      let exportedData = try Store.getDataRepresentation(for: store)

      savePanel.beginSheetModal(for: NSApp.keyWindow!) { response in
        guard response == .OK,
              let url = savePanel.url else {
          Log.data.info("Export cancelled")
          return
        }

        do {
          try exportedData.write(to: url)
          Log.data.info("Data saved to \(url.path)")
        }
        catch {
          Log.data.error("Failed to save data: \(error)")
        }
      }
    }
    catch {
      Log.data.error("Failed to get data representation for store: \(error)")
    }
  }
}
