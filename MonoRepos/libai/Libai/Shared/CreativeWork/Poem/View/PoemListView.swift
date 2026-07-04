//
//  PoemListView.swift
//  Libai
//
//  Created by huahuahu on 2022/2/6.
//

import SwiftUI

struct PoemListView: View {
  let poem: [Poem]
  let useSectionHeader: Bool

  private func sectionData(from poems: [Poem]) -> [SectionDataWithIndex<Poem, Character>] {
    SectionDataWithIndex.sectionDataArray(from: poems) { poem in
      poem.title.getFirstCharIndex()!
    }
  }

  private func title(for sectionData: SectionDataWithIndex<Poem, Character>) -> String {
    "\(sectionData.charIndex) (\(sectionData.items.count))"
  }

  var sectionBasedView: some View {
    ForEach(sectionData(from: poem)) { sectionData in
      Section {
        ForEach(sectionData.items) {
          poem in
          NavigationLink(value: poem) {
            PoemCell(poem: poem)
          }
        }
      } header: {
        Text(title(for: sectionData))
          .id(String(sectionData.charIndex))
      }
    }
  }

  var plainView: some View {
    ForEach(poem) {
      poem1 in
      NavigationLink(value: poem1) {
        PoemCell(poem: poem1)
      }
    }
  }

  var body: some View {
    if useSectionHeader {
      sectionBasedView
    }
    else {
      plainView
    }
  }
}

struct PoemListView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      List {
        PoemListView(
          poem: [.demo],
          useSectionHeader: true
        )
      }
      .listStyle(.plain)
    }
  }
}
