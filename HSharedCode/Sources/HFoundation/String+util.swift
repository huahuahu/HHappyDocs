//
//  String+util.swift
//  HFoundation
//
//  Created by tigerguo on 2023/4/21.
//

import Foundation
import SwiftSoup

public extension String {
  /// Parse string as html and make sure the html's meta data has set charset to utf8
  /// - Returns: A html with charset set to utf8
  func getUTF8Html() -> String? {
    do {
      let doc: Document = try SwiftSoup.parse(self)
      let head = doc.head()
      if let charsetMeta = try head?.select("meta[charset]"), !charsetMeta.isEmpty() {
        try charsetMeta.attr("charset", "UTF-8")
      }
      else {
        let charsetMeta = try doc.createElement("meta")
        try charsetMeta.attr("charset", "UTF-8")
        try head?.appendChild(charsetMeta)
      }
      return try doc.outerHtml()
    }
    catch {
      print("error \(error)")
      return nil
    }
  }

  func removeEmptyLines() -> String {
    self
      .split(separator: "\n")
      .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
      .joined(separator: "\n")
  }
}
