//
//  PoemGenreView.swift
//  Libai
//
//  Created by huahuahu on 2022/2/6.
//

import SwiftUI

struct PoemGenreView: View {
  init(genre: String?) {
    self.genre = genre
  }

  let genre: String?
  var body: some View {
    if let genre = genre {
      Text(genre)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
//        .background(Color.secondaryBackground)
        .padding(.horizontal, 10)
    }
    else {
      EmptyView()
    }
  }
}

struct PoemGenreView_Previews: PreviewProvider {
  static var previews: some View {
    PoemGenreView(genre: "五言古诗")
  }
}
