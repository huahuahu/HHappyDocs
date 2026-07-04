//
//  HDataType.swift
//  ClipboardInspector
//
//  Created by tigerguo on 2023/3/25.
//

import Foundation
#if os(iOS) || os(visionOS)
  import UIKit
#elseif os(macOS)
  import AppKit
#endif

enum HDataType {
  case data(data: Data)
  case string(string: String, fileExt: String)
  #if os(iOS) || os(visionOS)
    case image(image: UIImage)
  #elseif os(macOS)
    case image(image: NSImage)
  #endif

  case unknown

  init(raw: Any, fileExt: String?) {
    switch raw {
    case let data as Data:
      self = .data(data: data)
    case let string as String:
      let fileExt = fileExt ?? "txt"
      self = .string(string: string, fileExt: fileExt)
    #if os(iOS) || os(visionOS)
      case let image as UIImage:
        self = .image(image: image)
    #elseif os(macOS)
      case let image as NSImage:
        self = .image(image: image)
    #endif
    default:
      self = .unknown
    }
  }

  func canPreview() -> Bool {
    switch self {
    case .data, .unknown:
      return false
    case .string, .image:
      return true
    }
  }
}

extension HDataType {
  init(_ representation: HPasteboardItemRepresentation) {
    self = .init(
      raw: representation.value,
      fileExt: representation.utType?.preferredFilenameExtension
    )
  }
}
