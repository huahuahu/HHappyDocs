//
//  SearchProgressView.swift
//  HDiary
//
//  Created by tigerguo on 2025/4/12.
//

#if os(iOS)

import SwiftUI

extension SearchView {
  @MainActor struct SearchProgressView: View {
    var body: some View {
      ProgressView {
        Text(DiaryStringKey.Search.searching)
      }
    }
  }
}

#Preview(body: { @MainActor in
  NavigationStack {
    SearchView.SearchProgressView()
  }
})

#endif
