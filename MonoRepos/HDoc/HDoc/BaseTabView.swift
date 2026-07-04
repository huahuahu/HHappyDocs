//
//  BaseTabView.swift
//  HDoc
//
//  Created by tigerguo on 2023/12/29.
//

import HDocAppConstants
import HFoundation
import HLocalization
import HUIComponent
import SwiftUI

@MainActor
struct BaseTabView: View {
  @Environment(UserPreferences.self) private var userPreferences
  @Environment(AppRoute.self) private var appRoute

  var body: some View {
//    _ = Self._printChanges()
    @Bindable var appRoute = appRoute

    TabView(
      selection: $appRoute.selectedTab,
      content: {
        homeView
        libraryView
        settingsView
      }
    )
    .hDocLocalAuth(needAuth: userPreferences.appLockEnabled)
    .sensoryFeedback(.selection, trigger: appRoute.selectedTab)
  }

  private var homeView: some View {
    HomeView()
      .tabItem {
        Label(
          title: { Text(HDocString.home) },
          icon: {
            Image(hdocSymbol: .house)
          }
        )
      }
      .tag(HDocTab.home)
  }

  private var settingsView: some View {
    SettingsView()
      .tabItem {
        Label(
          title: { Text(HLocalizedString.setting) },
          icon: { Image(hdocSymbol: .gear) }
        )
      }
      .tag(HDocTab.settings)
  }

  private var libraryView: some View {
    LibraryEntryView()
      .tabItem {
        Label(
          title: { Text(HDocString.Common.library) },
          icon: { Image(hdocSymbol: .library) }
        )
      }
      .tag(HDocTab.library)
  }
}

#Preview("en") {
  BaseTabView()
    .previewEnvironment()
}

#Preview("cn") {
  BaseTabView()
    .previewEnvironment()
    .environment(\.locale, .cnMainland)
}
