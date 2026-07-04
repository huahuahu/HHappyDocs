//
//  HDescription.swift
//  ClipboardInspector
//
//  Created by tigerguo on 2023/3/25.
//

import Foundation

/// Used as navigation value for `String(describing:)`
struct HDescription: Hashable {
  let object: Any

  static func == (lhs: Self, rhs: Self) -> Bool {
    if type(of: lhs) != type(of: rhs) {
      return false
    }
    return String(describing: lhs) == String(describing: rhs)
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(String(describing: object))
  }
}
