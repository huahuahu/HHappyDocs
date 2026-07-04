//
//  PoemDetailView.swift
//  Libai
//
//  Created by huahuahu on 2021/12/26.
//

import AVFoundation
import CoreData
import SwiftUI

@MainActor
struct PoemDetailView: View {
  @FetchRequest(sortDescriptors: []) private var poems: FetchedResults<CDPoem>

  init(poemID: Int) {
    _poems = FetchRequest(sortDescriptors: [], predicate: NSPredicate(format: "id == %d", poemID))
  }

  @ViewBuilder
  var bodyView: some View {
    if let cdPoem = poems.first {
      PoemDetailDisplayView(poemDetail: PoemDetail(poem: Poem(cdPoem), annotates: []))
    }
    else {
      ContentUnavailableView(label: {
        Label(
          title: { Text("找不到该id的诗") },
          icon: { Image(systemName: "square") }
        )
      })
    }
  }

  var body: some View {
    bodyView
  }
}

struct PoemDetailView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      PoemDetailView(poemID: 1)
    }
  }
}
