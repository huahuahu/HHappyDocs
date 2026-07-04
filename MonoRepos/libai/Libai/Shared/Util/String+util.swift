//
//  String+util.swift
//  Libai (iOS)
//
//  Created by huahuahu on 2021/12/27.
//

import Foundation
import SwiftUI

extension String {
  func transformToPinyin() -> String? {
    applyingTransform(.mandarinToLatin, reverse: false)
  }

  func getFirstCharIndex() -> Character? {
    guard let firstChar = first else {
      return nil
    }
    return String(firstChar)
      .transformToPinyin()?
      .folding(options: .diacriticInsensitive, locale: .current)
      .uppercased()
      .first
  }

  func highLight(keyword: String, color: Color) -> AttributedString {
    var attributeString = AttributedString(self)
    let ranges = allRanges(of: keyword)

    for range in ranges {
      let startDistance = self.distance(from: self.startIndex, to: range.lowerBound)
      let lowerBound = attributeString.index(attributeString.startIndex, offsetByCharacters: startDistance)

      let endDistance = self.distance(from: self.startIndex, to: range.upperBound)
      let upperBound = attributeString.index(attributeString.startIndex, offsetByCharacters: endDistance)

      attributeString[lowerBound ..< upperBound].foregroundColor = color
    }

    return attributeString
  }

  func markdownToAttributed() -> AttributedString {
    do {
      return try AttributedString(markdown: self, options: .init(allowsExtendedAttributes: true, interpretedSyntax: .inlineOnlyPreservingWhitespace, failurePolicy: .throwError)) /// convert to AttributedString
    }
    catch {
      return AttributedString("Error parsing markdown: \(error)")
    }
  }

  func chineseCompare(_ other: String) -> ComparisonResult {
    let locale = Locale(identifier: "zh_Hans_CN")
    return compare(other, options: [], range: nil, locale: locale)
  }

//    func attributeStringWithFirstLineHeadIndent() -> AttributedString {
//        var attr = AttributedString(self)
//        attr.uiKit.paragraphStyle?.firstLineHeadIndent = 12.0
//        return attr
//    }

  init(dataSetName: StaticString) {
    guard let data = NSDataAsset(name: "\(dataSetName)")?.data,
          let string = String(data: data, encoding: .utf8)
    else {
      fatalError("No data from data set")
    }
    self = string
  }

  #if os(iOS)
    func rectUsing(_ font: UIFont) -> CGSize {
      let userAttributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: UIColor.black,
      ]
      return (self as NSString).size(withAttributes: userAttributes)
    }
  #endif

  func expand(to target: Int) -> String {
    let originalCount = count
    if originalCount < target {
      let appendString = Array(repeating: " ", count: target - originalCount).reduce(into: "") { $0.append(contentsOf: $1) }
      let result = appending(appendString)
      return result
    }
    else {
      return self
    }
  }

  public func allRanges(
    of aString: String,
    options: String.CompareOptions = [],
    range: Range<String.Index>? = nil,
    locale: Locale? = nil
  ) -> [Range<String.Index>] {
    // the slice within which to search
    let slice = (range == nil) ? self[...] : self[range!]

    var previousEnd = startIndex
    var ranges = [Range<String.Index>]()

    while let r = slice.range(
      of: aString, options: options,
      range: previousEnd ..< endIndex,
      locale: locale
    ) {
      if previousEnd != endIndex { // don't increment past the end
        previousEnd = index(after: r.lowerBound)
      }
      ranges.append(r)
    }

    return ranges
  }
}

struct StringKey: Identifiable {
  init(str: String) {
    self.str = str
  }

  let str: String

  var id: String {
    str
  }
}

extension Character: @retroactive Identifiable {
  public var id: String {
    "\(self)"
  }
}
