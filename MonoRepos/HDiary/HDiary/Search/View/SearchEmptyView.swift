//
//  SearchEmptyView.swift
//  HDiary
//
//  Created by tigerguo on 2025/3/26.
//

import SFSafeSymbols
import SwiftUI

extension SearchView {
  @MainActor
  struct EmptyResultView: View {
    var body: some View {
      ContentUnavailableView {
        Label {
          Text(DiaryStringKey.Search.emptyResult)
        } icon: {
          Image(systemSymbol: .magnifyingglass)
        }
        .font(.headline)
        .foregroundStyle(.secondary)
      }
    }
  }
}

#Preview {
  List {
    SearchView.EmptyResultView()
  }
//    .listStyle(.plain)
  .previewEnvironment()
}
