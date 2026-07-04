//
//  SectionDataWithIndex.swift
//  Libai (iOS)
//
//  Created by huahuahu on 2022/4/10.
//

import Foundation

struct SectionDataWithIndex<T: Identifiable, IndexType: Identifiable & Hashable & Equatable>: Identifiable {
  var id: IndexType {
    charIndex
  }

  let charIndex: IndexType
  let items: [T]

  static func sectionDataArray(from items: [T], itemToIndexTypeConverter: (T) -> IndexType) -> [Self] {
    var currentIndex: IndexType
    var results = [Self]()
    for item in items {
      currentIndex = itemToIndexTypeConverter(item)
      if let last = results.last {
        if last.charIndex == currentIndex {
          var newItems = last.items
          newItems.append(item)
          let newLast = Self(charIndex: last.charIndex, items: newItems)
          results[results.endIndex - 1] = newLast
        }
        else {
          hAssertion(!results.map(\.charIndex).contains(currentIndex), "\(item) order incorrect ")
          let sectionDataWithIndex = Self(charIndex: currentIndex, items: [item])
          results.append(sectionDataWithIndex)
        }
      }
      else {
        let sectionDataWithIndex = Self(charIndex: currentIndex, items: [item])
        results.append(sectionDataWithIndex)
      }
    }

    return results
  }
}
