//
//  AgeCompareView.swift
//  Libai
//
//  Created by huahuahu on 2022/3/17.
//

import CoreData
import SwiftUI

@MainActor
struct AgeCompareView: View {
  @FetchRequest(sortDescriptors: [SortDescriptor(\.birthYear, order: .forward)]) private var empires: FetchedResults<CDEmpire>

  private func listFor(_ lifeSpans: [LifeSpan]) -> some View {
    LifeSpanList(lifeSpans: lifeSpans)
  }

  private var lifeSpans: [LifeSpan] {
    empires.map {
      LifeSpan(name: $0.templeName, birthYear: $0.birthYear, deathYear: $0.deathYear)
    }
  }

  @ViewBuilder
  var content: some View {
    VStack {
      listFor(lifeSpans.reduce(into: [.libai]) { $0.append($1) })
    }
  }

  var body: some View {
    content
      .navigationTitle(PredefinedString.ageCompare)
  }
}

struct AagCompare_Previews: PreviewProvider {
  static var previews: some View {
    AgeCompareView()
  }
}
