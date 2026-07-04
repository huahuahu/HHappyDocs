//
//  PoemSearchEngine.swift
//  Libai
//
//  Created by huahuahu on 2022/5/30.
//

import Combine
import Foundation
import SwiftUI

struct SearchedPoem: Identifiable, Hashable {
  static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.poemID == rhs.poemID && lhs.tags == rhs.tags
  }

  let matchReason: SearchMatchReason
  let poemID: Int
  let title: AttributedString
  let content: DoubleAttrString?
  let tags: [AttributedString]?

  var id: Int {
    poemID
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(poemID)
  }

  static let demo = Self(matchReason: [.content], poemID: 1, title: "", content: nil, tags: nil)
}

struct SearchMatchReason: OptionSet, Identifiable {
  let rawValue: Int

  static let title = Self(rawValue: 1 << 0)
  static let content = Self(rawValue: 1 << 1)
  static let tag = Self(rawValue: 1 << 2)
  static let location = Self(rawValue: 1 << 3)
  static let translatedContent = Self(rawValue: 1 << 4)

  static let all: SearchMatchReason = [.title, .content, .tag, .location, .translatedContent]

  var id: Int { rawValue }

  var labelText: String {
    switch self {
    case .title:
      return PredefinedString.title
    case .content:
      return PredefinedString.content
    case .tag:
      return PredefinedString.tag
    case .location:
      return PredefinedString.location
    case .translatedContent:
      return PredefinedString.translatedContent
    case .all:
      return PredefinedString.all
    default:
      return PredefinedString.all
    }
  }

  func expand() -> [Self] {
    var result = [Self]()
    if contains(.title) {
      result.append(.title)
    }
    if contains(.content) {
      result.append(.content)
    }

    if contains(.tag) {
      result.append(.tag)
    }
    if contains(.location) {
      result.append(.location)
    }
    if contains(.translatedContent) {
      result.append(.translatedContent)
    }

    return result
  }
}

final class PoemSearchEngine: ObservableObject {
//  @Published var poems: [Poem] = []
//  @Published var searchWord: String = ""
//  @Published private(set) var results: [SearchedPoem]?
//
//  private var cancellabels = Set<AnyCancellable>()

  init() {}

  func filter(poems: [Poem], keyword: String) -> [SearchedPoem]? {
    if keyword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      return nil
    }
    let result = poems
      .compactMap { poem -> SearchedPoem? in
        var matchReason: SearchMatchReason = []
        let attrTitle = poem.title.highLight(keyword: keyword, color: .accentColor)
        if poem.title.contains(keyword) {
          matchReason.insert(.title)
        }

        var content: DoubleAttrString?
        if poem.content.contains(keyword),
           let matchedContent = poem.content.replacingOccurrences(of: "\n", with: " ")
           .highLightAndSeperate(keyword: keyword, color: .accentColor) {
          matchReason.insert([.content])
          content = matchedContent
        }

        let tags: [AttributedString] = poem.tags.filter { $0.contains(keyword) }
          .map { $0.highLight(keyword: keyword, color: .accentColor)
          }

        if !tags.isEmpty {
          matchReason.insert([.tag])
        }

        if matchReason.isEmpty {
          return nil
        }
        return SearchedPoem(
          matchReason: matchReason,
          poemID: poem.id,
          title: attrTitle,
          content: content,
          tags: tags.isEmpty ? nil : tags
        )
      }
    return result
  }
}
