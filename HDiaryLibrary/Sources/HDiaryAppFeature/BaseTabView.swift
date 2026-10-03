//
//  BaseTabView.swift
//  HDiary
//
//  Created by tigerguo on 2023/6/17.
//

#if os(iOS)

import HDiaryConstants
import HDiaryModel
import HDiarySearch
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
    HDiaryTabShell(
      selection: $appRoute.selectedTab,
      searchViewModel: $searchViewModel,
      supportsSearch: shouldSupportSearch,
      content: MomentTab(isSelected: appRoute.selectedTab == .content).environment(searchViewModel),
      library: libraryView,
      settings: settingView
    )
    .sensoryFeedback(.selection, trigger: appRoute.selectedTab)
    .onAppear {
      guard !hasPerformedStartupTask else {
        return
      }
      hasPerformedStartupTask = true
      Log.common.log(level: DiagnosticLogging.level(for: .info), "Performing startup task")
      StartupDataMaintenanceService().runLoggingFailures(in: modelContext)
      modelContext.undoManager = undoManager
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

    }))
  }

  @ViewBuilder
  private var libraryView: some View {
    LibraryView(isSelected: .init(get: {
      appRoute.selectedTab == .library
    }, set: { _ in

    }))
  }

}

/// The real app and page snapshots share tab labels, selection, and search placement.
@MainActor
struct HDiaryTabShell<Content: View, Library: View, Settings: View>: View {
  @Binding var selection: HDiaryTab
  @Binding var searchViewModel: SearchViewModel
  let supportsSearch: Bool
  let content: Content
  let library: Library
  let settings: Settings

  var body: some View {
    TabView(selection: $selection) {
      content
        .if(supportsSearch, transform: { view in
          view.searchable(searchViewModel: $searchViewModel)
        })
        .tabItem {
          Label {
            Text(DiaryStringKey.moments)
          } icon: {
            Image(systemName: "list.dash")
          }
        }
        .tag(HDiaryTab.content)
      library
        .tabItem {
          Label(
            title: { Text(DiaryStringKey.libraryTabItemLabel) },
            icon: { Image(systemName: "cube.box") }
          )
        }
        .tag(HDiaryTab.library)
      settings
        .tabItem {
          Label(HLocalizedString.setting, systemImage: "gear")
        }
        .tag(HDiaryTab.setting)
    }
  }
}

#endif
