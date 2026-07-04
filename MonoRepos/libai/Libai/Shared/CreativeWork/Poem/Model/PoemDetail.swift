//
//  PoemDetail.swift
//  Libai
//
//  Created by huahuahu on 2022/1/8.
//

import Foundation
import SwiftUI

struct Annotate: Decodable, Identifiable, Equatable {
  let poemID: Int
  let start: Int
  let end: Int
  let content: String
  let selectedContent: String
  var id: String {
    "\(poemID)-\(start)-\(end)"
  }

  func getMarkDownUrlWith<T: StringProtocol>(rawContent: T) -> String {
    let pattern = URLHandler.Pattern(host: .annotate, value: content)
    return "[\(rawContent)](\(pattern.url.absoluteString))"
  }
}

struct PoemDetail: Equatable {
  init(poem: Poem, annotates: [Annotate]) {
    self.poem = poem
    self.annotates = annotates
    var content = poem.content

    annotates
      .filter { $0.poemID == poem.id }
      .sorted { $0.start > $1.start }
      .forEach { annotate in
        let charStartIndex = String.Index(utf16Offset: annotate.start, in: content).samePosition(in: content)
        let charEndIndex = String.Index(utf16Offset: annotate.end, in: content).samePosition(in: content)
        if let charStartIndex = charStartIndex, let charEndIndex = charEndIndex {
          let annotatedText = content[charStartIndex ..< charEndIndex]
          content.replaceSubrange(charStartIndex ..< charEndIndex, with: annotate.getMarkDownUrlWith(rawContent: annotatedText))
          dataLog("replace \(annotate) \(content)")
        }
        else {
          dataLog("ignore \(annotate)")
        }
      }
    displayContent = content
  }

  let poem: Poem
  let annotates: [Annotate]

  let displayContent: String
}

extension PoemDetail {
  static let demo = PoemDetail(poem: .demo, annotates: [])
}
