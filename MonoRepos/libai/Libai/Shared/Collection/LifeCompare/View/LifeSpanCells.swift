//
//  LifeSpanCells.swift
//  Libai
//
//  Created by huahuahu on 2022/3/17.
//

import SwiftUI

struct LifeSpanCells: View {
  @Binding var lifeSpans: [LifeSpan]
  var body: some View {
    ForEach(lifeSpans) { lifeSpan in
      LifeSpanCell(lifeSpan: lifeSpan)
    }
    .onMove { indexSet, offset in
      lifeSpans.move(fromOffsets: indexSet, toOffset: offset)
    }
  }
}

struct LifeSpanCells_Previews: PreviewProvider {
  static var previews: some View {
    List {
      LifeSpanCells(lifeSpans: .constant([.libai]))
    }
  }
}
