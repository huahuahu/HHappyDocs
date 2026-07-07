//
//  SearchErrorView.swift
//  HDiary
//
//  Created by tigerguo on 2025/4/12.
//
#if os(iOS)

import HDiaryConstants
import SFSafeSymbols
import SwiftUI

extension SearchView {
  @MainActor struct SearchErrorView: View {
    let errorText: String
    var body: some View {
      VStack(spacing: 16) {
        Image(systemSymbol: .exclamationmarkCircle) // 改用错误提示图标
          .font(.system(size: 48))
          .foregroundStyle(.secondary)

        VStack(spacing: 8) {
          Text(DiaryStringKey.Search.searchError) // 更改为错误状态的提示
            .font(.headline)
            .foregroundStyle(.primary)

          Text(errorText)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
      }
      .padding()
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
  }
}

#Preview(body: { @MainActor in
  NavigationStack {
    SearchView.SearchErrorView(errorText: "请稍后重试") // 更改为更通用的错误提示文案
  }
})

#endif
