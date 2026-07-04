//
//  HPasteboardNoPermissionInfo.swift
//  ClipboardInspector
//
//  Created by tigerguo on 2023/7/8.
//

import Foundation

struct HPasteboardNoPermissionInfo {
  init(numberOfItems: Int, hasColors: Bool, hasImages: Bool, hasStrings: Bool, hasURLs: Bool, types: [[String]]) {
    self.numberOfItems = numberOfItems
    self.hasColors = hasColors
    self.hasImages = hasImages
    self.hasStrings = hasStrings
    self.hasURLs = hasURLs
    self.types = types
  }

  let numberOfItems: Int
  let hasColors: Bool
  let hasImages: Bool
  let hasStrings: Bool
  let hasURLs: Bool
  let types: [[String]]

  var colorInfo: PasteboardBoolInfo {
    PasteboardBoolInfo(
      info: "A Boolean value that indicates whether the pasteboard contains contains a nonempty array of colors.",
      value: hasColors,
      label: "hasColors"
    )
  }

  var imageInfo: PasteboardBoolInfo {
    PasteboardBoolInfo(
      info: "A Boolean value that indicates whether the pasteboard contains a nonempty array of images.",
      value: hasImages,
      label: "hasImages"
    )
  }

  var stringInfo: PasteboardBoolInfo {
    PasteboardBoolInfo(
      info: "A Boolean value that indicates whether the pasteboard contains a nonempty array of strings.",
      value: hasStrings,
      label: "hasString"
    )
  }

  var urlInfo: PasteboardBoolInfo {
    PasteboardBoolInfo(
      info: "A Boolean value that indicates whether the pasteboard contains a nonempty array of URLs.",
      value: hasURLs,
      label: "hasURLs"
    )
  }
}

struct PasteboardBoolInfo {
  let info: String
  let value: Bool
  let label: String
}

extension HPasteboardNoPermissionInfo {
  static let empty = HPasteboardNoPermissionInfo(
    numberOfItems: 0,
    hasColors: false,
    hasImages: false,
    hasStrings: false,
    hasURLs: false,
    types: []
  )

  static let image = HPasteboardNoPermissionInfo(
    numberOfItems: 2,
    hasColors: false,
    hasImages: true,
    hasStrings: true,
    hasURLs: false,
    types: [
      ["public.utf8-plain-text"],
      ["public.jpeg"],
    ]
  )
}
