//
//  PoemFilterView.swift
//  Libai
//
//  Created by huahuahu on 2022/2/6.
//

import SwiftUI

struct PoemFilterView: View {
  @Binding var selectedGenre: String
  let allGenres: [GenreFilterItem]
  var body: some View {
    Picker("体裁", selection: $selectedGenre) {
      ForEach(allGenres) { item in
        Text("\(item.genre) (\(item.count))")
          .tag(item.genre)
      }
    }
    .pickerStyle(.menu)
  }
}

struct PoemFilterView_Previews: PreviewProvider {
  @State static var selectedGenre: String = "五言古诗"
  static var previews: some View {
    PoemFilterView(
      selectedGenre: $selectedGenre,
      allGenres: [GenreFilterItem(genre: "五言古诗", count: 2), GenreFilterItem(genre: "五言绝句", count: 3)]
    )
  }
}
