//
//  AnnalSearchEngine.swift
//  Libai (iOS)
//
//  Created by huahuahu on 2022/5/29.
//

import Combine
import Foundation
import SwiftUI

struct SearchedAnnal: Identifiable, Hashable {
  static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }

  let id: Int
  let ageStr: AttributedString
  let empireStr: AttributedString
  let summary: AttributedString?
  let content: DoubleAttrString?
  let locationsStr: AttributedString?
  let rawAnnal: AnnalToDisplay
}

enum AnnalSearchEngine {
  static func searchResult(for searchWord: String, in annales: [AnnalToDisplay]) -> [SearchedAnnal]? {
    hLog("latestAnnals: \(annales.count), latestSearchWord: \(searchWord)", scenerio: .data)
    if searchWord.isEmpty {
      return nil
    }

    let results = annales.compactMap { annal -> SearchedAnnal? in
      var shouldShow = false
      let ageStr = "\(annal.age) 岁".highLight(keyword: searchWord, color: .accentColor)
      if ageStr.range(of: searchWord) != nil {
        shouldShow = true
      }

      let empireStr = annal.empireStr.highLight(keyword: searchWord, color: .accentColor)
      if !shouldShow, empireStr.range(of: searchWord) != nil {
        shouldShow = true
      }

      var summaryAnnal: AttributedString?
      if annal.summary?.range(of: searchWord) != nil {
        shouldShow = true
        summaryAnnal = annal.summary?.highLight(keyword: searchWord, color: .accentColor)
      }

      let content = String(annal.content.markdownToAttributed().characters).replacingOccurrences(of: "\n", with: " ")
        .highLightAndSeperate(keyword: searchWord, color: Color.accentColor)
      if content != nil {
        shouldShow = true
      }

      if shouldShow {
        return SearchedAnnal(
          id: annal.id,
          ageStr: ageStr,
          empireStr: empireStr,
          summary: summaryAnnal,
          content: content,
          locationsStr: nil,
          rawAnnal: annal
        )
      }
      else {
        return nil
      }
    }

    return results
  }
}
