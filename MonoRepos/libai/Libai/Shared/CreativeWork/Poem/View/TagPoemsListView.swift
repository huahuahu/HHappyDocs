//
//  TagPoemsListView.swift
//  Libai
//
//  Created by huahuahu on 2022/2/6.
//

import CoreData
import SwiftUI

@MainActor
struct TagPoemsListView: View {
  let tag: String
  @FetchRequest(sortDescriptors: []) private var cdPoems: FetchedResults<CDPoem>
  init(tag: String) {
    self.tag = tag
    _cdPoems = FetchRequest(sortDescriptors: [SortDescriptor(\.title, order: .forward)])
  }

  private var poems: [Poem] {
    let allPoems = cdPoems.map { Poem($0) }.sorted {
      $0.title.chineseCompare($1.title) == .orderedAscending
    }
    return FilterModel(poems: allPoems).filteredBy(tag: tag)
  }

  var body: some View {
    GeometryReader { geo in
      ScrollViewReader { scrollProxy in
        List {
          PoemListView(
            poem: poems,
            useSectionHeader: true
          )
        }
        .listStyle(.plain)
        .overlay(alignment: .trailing) {
          PoemIndexView(poems: poems, containerHeight: .constant(geo.size.width), scrollProxy: scrollProxy)
            .fixedSize()
            .offset(x: -20, y: 0)
        }
      }
    }
    .navigationTitle(tag)
  }
}

struct TagPoemsListView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      TagPoemsListView(tag: "不遇")
    }
  }
}
