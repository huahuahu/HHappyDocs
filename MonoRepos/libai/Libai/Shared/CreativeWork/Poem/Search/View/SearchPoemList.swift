//
//  SearchPoemList.swift
//  Libai
//
//  Created by huahuahu on 2022/5/30.
//

import SwiftUI

struct SearchPoemList: View {
  let searchedPoems: [SearchedPoem]
  let reason: SearchMatchReason

  private var tags: [String] {
    searchedPoems.compactMap(\.tags)
      .flatMap { $0 }
      .map { String($0.characters) }
      .reduce(into: Set<String>()) { partialResult, ele in
        partialResult.insert(ele)
      }
      .map { $0 }
  }

  private var shouldShowHeader: Bool {
    reason == .tag && !searchedPoems.compactMap(\.tags).isEmpty
  }

  @ViewBuilder
  private var header: some View {
    let tags = tags
    if reason == .tag, !tags.isEmpty {
      ForEach(0 ..< tags.count, id: \.self) { index in
        HStack {
          NavigationLink(value: TagKey(tag: tags[index])) {
            Label(tags[index], systemImage: SystemImage.tag)
          }
        }
      }
    }
    else {
      EmptyView()
    }
  }

  private var poemList: some View {
    ForEach(searchedPoems) { poem in
      SearchPoemCell(searchedPoem: poem, reason: reason)
    }
  }

  var body: some View {
    List {
      if shouldShowHeader {
        header
        Section(PredefinedString.poem) {
          poemList
        }
      }
      else {
        poemList
      }
    }
    .listStyle(.plain)
  }
}

struct SearchPoemList_Previews: PreviewProvider {
  static var previews: some View {
    SearchPoemList(searchedPoems: [.demo], reason: .all)
  }
}
