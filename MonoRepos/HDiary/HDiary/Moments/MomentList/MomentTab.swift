//
//  MomentTab.swift
//  HDiary
//
//  Created by tigerguo on 2025/4/15.
//

import HDiaryConstants
import HDiaryModel
import SwiftData
import SwiftUI

@MainActor struct MomentTab: View {
  @Environment(SearchViewModel.self) private var searchViewModel
  @Environment(\.isSearching) private var isSearching
  @Environment(HDiaryRoute.self) private var appRoute
  private let isSelected: Bool

  init(isSelected: Bool) {
    self.isSelected = isSelected
  }

  var body: some View {
    @Bindable var searchViewModel = searchViewModel
    @Bindable var appRoute = appRoute
    NavigationStack(path: $appRoute.contentNavigationStore.path) {
      Group {
        if isSearching {
          SearchView(searchViewModel: searchViewModel)
        }
        else {
          MomentContainerView()
        }
      }
      .navigationTitle(Text(DiaryStringKey.happyListNavigationTitle))
    }
    .environment(appRoute.contentNavigationStore)
    .onOpenURL(perform: { url in
      if isSelected {
        Log.Navigation.common.info("handle url in moment list tab")
        appRoute.contentNavigationStore.handle(url)
      }
    })
    .onChange(of: isSearching, initial: true, { oldValue, newValue in
      Log.search.debug("isSearching: \(oldValue) -> \(newValue)")
      if oldValue != newValue, newValue {
        searchViewModel.startRecommend()
      }
    })
  }
}

private struct MomentContainerView: View {
  @Environment(\.modelContext) private var modelContext
  @State private var recentListModel = RecentMomentListModel()
  var body: some View {
    MomentListScreen(model: recentListModel.mode)
      .task {
        recentListModel.updateMode(modelContext: modelContext)
      }
  }
}
