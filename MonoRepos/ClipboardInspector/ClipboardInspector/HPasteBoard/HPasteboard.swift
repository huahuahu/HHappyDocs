//
//  HPasteboard.swift
//  ClipboardInspector
//
//  Created by tigerguo on 2023/3/18.
//

import Foundation
#if os(iOS) || os(visionOS)
  import UIKit
#elseif os(macOS)
  import AppKit
#endif

/// A wrapper around UIPasteboard & NSPasteboard
final class HPasteboard {
  static let shared = HPasteboard()
  // Make is singleton
  private init() {}

  func getItems() -> [HPasteboardItem] {
    #if os(iOS) || os(visionOS)
      let uiItems = UIPasteboard.general.items
      return uiItems
        .filter { !$0.isEmpty }
        .map { uiItem in
          let representations = uiItem.map { key, value in
            HPasteboardItemRepresentation(type: key, value: value)
          }
          .sorted { $0.type < $1.type }
          return HPasteboardItem(representations: representations)
        }
    #elseif os(macOS)
      guard let items = NSPasteboard.general.pasteboardItems else {
        return []
      }
      return items.map { nsPasteboardItem in
        let representations = nsPasteboardItem.types.compactMap({ type in
          if let string = nsPasteboardItem.string(forType: type) {
            return HPasteboardItemRepresentation(type: type.rawValue, value: string)
          }
          if let data = nsPasteboardItem.data(forType: type) {
            if type == .png, let image = NSImage(data: data) {
              return HPasteboardItemRepresentation(type: type.rawValue, value: image)
            }
            return HPasteboardItemRepresentation(type: type.rawValue, value: data)
          }
          return nil
        })
        return HPasteboardItem(representations: representations)
      }
    #endif
  }

  #if os(iOS) || os(visionOS)
    func getNoPermissionInfo() -> HPasteboardNoPermissionInfo {
      let pasteboard = UIPasteboard.general
      return HPasteboardNoPermissionInfo(
        numberOfItems: pasteboard.numberOfItems,
        hasColors: pasteboard.hasColors,
        hasImages: pasteboard.hasImages,
        hasStrings: pasteboard.hasStrings,
        hasURLs: pasteboard.hasURLs,
        types: pasteboard.types(forItemSet: nil) ?? []
      )
    }
  #endif

  func clearContent() {
    #if os(iOS) || os(visionOS)
      UIPasteboard.general.items = []
    #elseif os(macOS)
      NSPasteboard.general.clearContents()
    #endif
  }
}
