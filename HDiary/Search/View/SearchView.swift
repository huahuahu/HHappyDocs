//
//  SearchView.swift
//  HDiary
//
//  Created by tigerguo on 2025/3/26.
//

import SwiftUI

@MainActor
struct SearchView: View {
  let searchViewModel: SearchViewModel
  var body: some View {
    switch searchViewModel.state {
    case .idle:
      EmptyView()

    case let .recommend(moments: moments):
      SearchRecommendView(recommendedMoments: moments)

    case .searching:
      SearchProgressView()

    case .searchSucceed(let moments):
      if moments.isEmpty {
        EmptyResultView()
      }
      else {
        ResultView(searchResult: moments)
      }

    case .searchError(let error):
      SearchErrorView(errorText: error.localizedDescription)
    }
  }
}
