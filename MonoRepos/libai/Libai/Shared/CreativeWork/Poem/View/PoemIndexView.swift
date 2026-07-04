//
//  PoemIndexView.swift
//  Libai (iOS)
//
//  Created by huahuahu on 2022/4/16.
//

import SwiftUI

struct PoemIndexView: View {
  let poems: [Poem]
  @Binding var containerHeight: Double
  let scrollProxy: ScrollViewProxy

  private func sectionDatas() -> [SectionDataWithIndex<Poem, Character>] {
    SectionDataWithIndex.sectionDataArray(from: poems) { poem in
      poem.title.getFirstCharIndex()!
    }
  }

  private func title(for sectionData: SectionDataWithIndex<Poem, Character>) -> String {
    "\(sectionData.charIndex) (\(sectionData.items.count))"
  }

  var body: some View {
    IndexView(
      containerHeight: $containerHeight,
      indexItems: .constant(
        sectionDatas().map { sectionData in
          IndexItem(displayText: String(sectionData.charIndex)) {
            dataLog("tapped \(sectionData.charIndex)")
            scrollProxy.scrollTo(String(sectionData.charIndex), anchor: .top)
          }
        })
    )
  }
}

struct PoemIndexView_Previews: PreviewProvider {
  static var previews: some View {
    ScrollViewReader { proxy in
      List {
        PoemIndexView(poems: [], containerHeight: .constant(100), scrollProxy: proxy)
      }
    }
  }
}
