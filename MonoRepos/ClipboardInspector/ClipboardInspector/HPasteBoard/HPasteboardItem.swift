//
//  HPasteboardItem.swift
//  ClipboardInspector
//
//  Created by tigerguo on 2023/3/18.
//

import Foundation
import UniformTypeIdentifiers

struct HPasteboardItem: Identifiable {
  var id: String {
    representations.map { $0.id }.joined(separator: ";")
  }

  let representations: [HPasteboardItemRepresentation]
}

struct HPasteboardItemRepresentation: Identifiable, CustomStringConvertible, Hashable {
  init(type: String, value: Any) {
    self.type = type
    self.value = value
    self.utType = UTType(type)
  }

  let utType: UTType?

  let type: String
  let value: Any

  var id: String {
    "\(type): \(value)"
  }

  var description: String {
    "\(value)"
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }

  static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }
}

extension HPasteboardItemRepresentation {
  static let plainText = HPasteboardItemRepresentation(type: "public.utf8-plain-text", value: "test")
  static let utf16text = HPasteboardItemRepresentation(type: "public.utf16-external-plain-text", value: "test")
}
