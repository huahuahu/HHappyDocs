//
//  LifeSpanCell.swift
//  Libai
//
//  Created by huahuahu on 2022/3/17.
//

import SwiftUI

struct LifeSpanCell: View {
  let lifeSpan: LifeSpan
  let dd = NumberFormatter()

  var body: some View {
    HStack {
      Text(lifeSpan.name)
      Text("\(lifeSpan.birthYear) - \(lifeSpan.deathYear) ")
      Spacer()
    }
  }
}

struct LifeSpanCell_Previews: PreviewProvider {
  static var previews: some View {
    List {
      LifeSpanCell(lifeSpan: .libai)
    }
  }
}
