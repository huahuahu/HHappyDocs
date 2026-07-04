//
//  String+search.swift
//  Libai
//
//  Created by tigerguo on 2024/3/2.
//

import Foundation
import SwiftUI

extension String {
  func highLightAndSeperate(keyword: String, color: Color) -> DoubleAttrString? {
    let extendCharCount = 20
    guard let range = range(of: keyword) else {
      return nil
    }

    let lowerBound: String.Index = {
      var remainsCount = extendCharCount
      var currentIndex = range.lowerBound
      while remainsCount > 0, currentIndex != self.startIndex {
        remainsCount -= 1
        currentIndex = self.index(before: currentIndex)
      }
      return currentIndex
    }()

    let upperBound: String.Index = {
      var remainsCount = extendCharCount
      var currentIndex = range.upperBound
      while remainsCount > 0, currentIndex != self.endIndex {
        remainsCount -= 1
        currentIndex = self.index(after: currentIndex)
      }
      return currentIndex
    }()

    let beforeString = String(self[lowerBound ..< range.upperBound])
    let afterString = String(self[range.upperBound ..< upperBound])

    let beforeAttrString = beforeString.highLight(keyword: keyword, color: color)
    let afterAttrString = afterString.highLight(keyword: keyword, color: color)
    return DoubleAttrString(first: beforeAttrString, last: afterAttrString)
  }
}
