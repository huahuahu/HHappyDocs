//
//  SearchRecommendView.swift
//  HDiary
//
//  Created by tigerguo on 2025/3/26.
//

import HDiaryModel
import SFSafeSymbols
import SwiftUI

extension SearchView {
  struct SearchRecommendView: View {
    let recommendedMoments: [Moment]

    var body: some View {
      if !recommendedMoments.isEmpty {
        List {
          Section {
            ForEach(recommendedMoments) { moment in
              NavigationLink(value: HDiaryDestination.moment(moment, editEnabled: true)) {
                MomentListItemView(moment: moment)
              }
            }
          } header: {
            recommendHeaderLabel
          }
        }
        .listStyle(.plain)
        .hDiaryNavigator()
      }
    }

    private var recommendHeaderLabel: some View {
      Label {
        Text(DiaryStringKey.Search.recommended)
          .font(.headline)
          .foregroundStyle(.primary)
      } icon: {
        if #available(iOS 18, *) {
          Image(systemSymbol: .wandAndSparkles)
            .foregroundStyle(.yellow)
            .symbolEffect(.bounce)
        }
        else {
          Image(systemSymbol: .wandAndStars)
            .foregroundStyle(.yellow)
        }
      }
      .padding(.vertical, 8)
    }
  }
}
