//
//  TagSortMenu.swift
//  HDiary
//
//  Created by tigerguo on 2025/1/15.
//

import HDiaryConstants
import HDiaryModel
import SwiftUI

@MainActor
struct TagSortMenu: View {
  @State private var selectedSortOrder: TagSortOrder = .name

  private let onSortOrderChanged: ((TagSortOrder) -> Void)?

  init(onSortOrderChanged: ((TagSortOrder) -> Void)? = nil) {
    self.onSortOrderChanged = onSortOrderChanged
  }

  var body: some View {
    Menu {
      ForEach(TagSortOrder.allCases) { tagSortOrder in
        Button {
          selectedSortOrder = tagSortOrder
        } label: {
          if selectedSortOrder == tagSortOrder {
            Label {
              Text(tagSortOrder.label)
            } icon: {
              Image(hDiarySymbol: .checkmark)
            }
          }
          else {
            Text(tagSortOrder.label)
          }
        }
      }
    } label: {
      Label {
        Text(DiaryStringKey.Common.sort)
      } icon: {
        Image(hDiarySymbol: .sort)
      }
    }
    .onChange(of: selectedSortOrder, initial: true) {
      onSortOrderChanged?(selectedSortOrder)
    }
  }
}

enum TagSortOrder: Sendable, CaseIterable, Identifiable, Hashable {
  case name
  case momentCount

  var id: Self { self }

  var label: LocalizedStringResource {
    switch self {
    case .name:
      return DiaryStringKey.Common.sortByName
    case .momentCount:
      return DiaryStringKey.Common.sortByMomentCount
    }
  }

  func sortTags(_ tags: [Tag]) -> [Tag] {
    typealias AreInIncreasingOrder = (Tag, Tag) -> Bool
    let namePredict: AreInIncreasingOrder = { $0.text.localizedStandardCompare($1.text) == .orderedAscending }
    let momentCountPredict: AreInIncreasingOrder = { ($0.moments?.count ?? 0) > ($1.moments?.count ?? 0) }

    let predicates: [AreInIncreasingOrder] = switch self {
    case .name: [namePredict, momentCountPredict]
    case .momentCount: [momentCountPredict, namePredict]
    }

    // https://sarunw.com/posts/how-to-sort-by-multiple-properties-in-swift/
    return tags.sorted { lhs, rhs in
      for predicate in predicates {
        if !predicate(lhs, rhs) && !predicate(rhs, lhs) {
          continue
        }

        return predicate(lhs, rhs)
      }

      return false
    }
  }
}

#Preview("TagPreview") {
  NavigationStack {
    List {
      Text(verbatim: "ss")
    }
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        TagSortMenu()
      }
    }
  }
}
