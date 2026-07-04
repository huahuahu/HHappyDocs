//
//  SearchResultView.swift
//  HDiary
//
//  Created by tigerguo on 2025/3/26.
//

import HDiaryModel
import SwiftUI

extension SearchView {
  @MainActor struct ResultView: View {
    let searchResult: [Moment]

    var body: some View {
      List {
        ForEach(searchResult) { moment in
          NavigationLink(value: HDiaryDestination.moment(moment, editEnabled: true)) {
            MomentListItemView(moment: moment)
          }
        }
      }
      .listStyle(.plain)
      .hDiaryNavigator()
    }
  }
}
