//
//  FavPoemList.swift
//  Libai (iOS)
//
//  Created by huahuahu on 2022/2/13.
//

import LibaiModel
import SwiftData
import SwiftUI

@MainActor
struct FavPoemList: View {
  @Query(sort: \FavPoem.date, order: .reverse) private var favPoems: [FavPoem]
  @FetchRequest(sortDescriptors: []) private var cdPoems: FetchedResults<CDPoem>

  @State private var sortOrder: FavPoemSortOrder = .addDateReverse
  init() {
    _cdPoems = FetchRequest(sortDescriptors: [SortDescriptor(\.title, order: .forward)])
  }

  private var favPoemEntities: [PoemWithDate] {
    let allpoems = cdPoems.map { Poem($0) }.reduce(into: [Int: Poem]()) { partialResult, poem in
      partialResult[poem.id] = poem
    }
    switch sortOrder {
    case .addDateForward:
      return favPoems
        .sorted { $0.date < $1.date }
        .compactMap {
          favPoem in allpoems[favPoem.id].map { poem in PoemWithDate(poem: poem, addedDate: favPoem.date) }
        }
    case .addDateReverse:
      return favPoems
        .sorted { $0.date > $1.date }
        .compactMap {
          favPoem in allpoems[favPoem.id].map { poem in PoemWithDate(poem: poem, addedDate: favPoem.date) }
        }
    case .alphaBetaForward:
      return favPoems
        .compactMap {
          favPoem in allpoems[favPoem.id].map { poem in PoemWithDate(poem: poem, addedDate: favPoem.date) }
        }.sorted {
          $0.poem.title.chineseCompare($1.poem.title) == .orderedAscending
        }
    case .alphabetaReverse:
      return favPoems
        .compactMap {
          favPoem in allpoems[favPoem.id].map { poem in PoemWithDate(poem: poem, addedDate: favPoem.date) }
        }.sorted {
          $0.poem.title.chineseCompare($1.poem.title) == .orderedDescending
        }
    }
  }

  @ViewBuilder
  var content: some View {
    if cdPoems.isEmpty {
      EmptyContentView()
    }
    else {
      List {
        ForEach(favPoemEntities) { poemWithDate in
          NavigationLink {
            PoemDetailView(poemID: poemWithDate.poem.id)
          } label: {
            switch sortOrder {
            case .addDateForward, .addDateReverse:
              PoemWithDateView(poem: poemWithDate.poem, date: poemWithDate.addedDate)
            case .alphaBetaForward, .alphabetaReverse:
              Text(poemWithDate.poem.title)
                .font(.title2)
                .foregroundStyle(.primary)
            }
          }
        }
      }
      .listStyle(.plain)
    }
  }

  var body: some View {
    content
      .toolbar(content: {
        toolbar
      })
      .navigationTitle(PredefinedString.favlist)
  }

  @ToolbarContentBuilder
  private var toolbar: some ToolbarContent {
    ToolbarItem(placement: .automatic) {
      Menu {
        Picker("选择排序方式", systemImage: SystemImage.sort.rawValue, selection: $sortOrder) {
          ForEach(FavPoemSortOrder.allCases) { order in
            Button(action: {
              self.sortOrder = order
            }, label: {
              Label(
                title: { Text(order.label) },
                icon: { order.image }
              )
            })
          }
        }
      } label: {
        Label(
          title: { Text("排序") },
          icon: { Image(systemImage: .sort) }
        )
      }
    }
  }
}

private enum FavPoemSortOrder: CaseIterable, Identifiable, Hashable {
  var id: Self {
    self
  }

  case addDateForward
  case addDateReverse
  case alphaBetaForward
  case alphabetaReverse

  var label: String {
    switch self {
    case .addDateForward:
      "收藏日期从旧到新"
    case .addDateReverse:
      "收藏日期从新到旧"
    case .alphaBetaForward:
      "拼音a-z"
    case .alphabetaReverse:
      "拼音z-a"
    }
  }

  var image: Image {
    switch self {
    case .addDateForward, .addDateReverse:
      return Image(systemImage: .date)
    case .alphaBetaForward, .alphabetaReverse:
      return Image(systemImage: .character)
    }
  }
}

private struct PoemWithDate: Identifiable {
  let poem: Poem
  let addedDate: Date

  init(poem: Poem, addedDate: Date) {
    self.poem = poem
    self.addedDate = addedDate
  }

  var id: Poem { poem }
}

@MainActor
private struct PoemWithDateView: View {
  @ScaledMetric private var paddingValue = 5.0

  let poem: Poem
  let date: Date
  var body: some View {
    VStack(alignment: .leading, content: {
      Text(date, style: .date)
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.vertical, paddingValue)

      Text(poem.title)
        .font(.title2)
        .foregroundStyle(.primary)
    })
  }
}

struct FavPoemList_Previews: PreviewProvider {
  static var previews: some View {
    FavPoemList()
  }
}
