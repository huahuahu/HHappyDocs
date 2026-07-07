//
//  SearchModifier.swift
//  HDiary
//
//  Created by tigerguo on 2025/3/26.
//

#if os(iOS)

import HDiaryConstants
import HDiarySearch
import SwiftUI

@MainActor
extension View {
  /// A modifier that adds a search bar to the view.
  /// - Parameter searchViewModel: The view model that handles the search logic.
  /// - Returns: A view with a search bar.
  func searchable(searchViewModel: Binding<SearchViewModel>) -> some View {
    self
      .searchable(text: searchViewModel.queryText)
      .onSubmit(of: .search) {
        Task {
          Log.search.info("search when submit")
          await searchViewModel.wrappedValue.search()
        }
      }
      .onChange(of: searchViewModel.queryText.wrappedValue, {
        Task {
          Log.search.info("search when text change")
          await searchViewModel.wrappedValue.search()
        }
      })
  }
}

#endif
