//
//  BaseTabView.swift
//  HDiary
//
//  Created by tigerguo on 2023/6/17.
//

import HDiaryConstants
import HDiaryModel
import HDiarySearch
import HDiaryServices
import HLocalization
import Observation
import SwiftData
import SwiftUI

@MainActor
struct BaseTabView: View {
  private static var firstMomentQuery = {
    var descriptor = FetchDescriptor<Moment>(predicate: #Predicate<Moment> { !$0.markedAsDelete })
    descriptor.fetchLimit = 1
    return descriptor
  }()

  @Environment(\.modelContext) private var modelContext
  @Environment(\.undoManager) private var undoManager
  @Environment(HDiaryRoute.self) private var appRoute
  @Environment(UserPreferences.self) private var userPreferences

  @Query private var moments: [Moment]
  @State private var hasPerformedStartupTask = false

  init() {
    _moments = Query(Self.firstMomentQuery)
  }

  @State private var searchViewModel = SearchViewModel()
  var body: some View {
    @Bindable var appRoute = appRoute
    TabView(selection: $appRoute.selectedTab) {
      contentView
        .tag(HDiaryTab.content)
      libraryView
        .tag(HDiaryTab.library)
      settingView
        .tag(HDiaryTab.setting)
    }
    .sensoryFeedback(.selection, trigger: appRoute.selectedTab)
    .onAppear {
      guard !hasPerformedStartupTask else {
        return
      }
      hasPerformedStartupTask = true
      Log.common.info("Performing startup task")
      StartupDataMaintenanceService().runLoggingFailures(in: modelContext)
      modelContext.undoManager = undoManager
    }
  }

  @ViewBuilder
  private var contentView: some View {
    MomentTab(isSelected: appRoute.selectedTab == .content)
      .environment(searchViewModel)
      .if(shouldSupportSearch, transform: { content in
        content
          .searchable(searchViewModel: $searchViewModel)
      })
      .tabItem {
        Label {
          Text(DiaryStringKey.moments)
        } icon: {
          Image(systemName: "list.dash")
        }
      }
  }

  private var shouldSupportSearch: Bool {
    #if DEBUG
      guard userPreferences.supportSearch else {
        return false
      }
    #endif
    return !moments.isEmpty
  }

  @ViewBuilder
  private var settingView: some View {
    SettingsView(isSelected: .init(get: {
      appRoute.selectedTab == .setting
    }, set: { _ in

    })).tabItem {
      Label(HLocalizedString.setting, systemImage: "gear")
    }
  }

  @ViewBuilder
  private var libraryView: some View {
    LibraryView(isSelected: .init(get: {
      appRoute.selectedTab == .library
    }, set: { _ in

    })).tabItem {
      Label(
        title: { Text(DiaryStringKey.libraryTabItemLabel) },
        icon: { Image(systemName: "cube.box") }
      )
    }
  }

}
