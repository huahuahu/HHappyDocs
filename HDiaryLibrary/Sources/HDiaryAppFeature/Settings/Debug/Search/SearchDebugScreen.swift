//
//  SearchDebugScreen.swift
//  HDiary
//
//  Created by tigerguo on 2025/3/26.
//

#if os(iOS)

import HDiaryConstants
import SwiftUI

extension SettingsView {
  @MainActor
  struct SearchDebugScreen: View {
    @Environment(UserPreferences.self) private var userPreferences
    var body: some View {
      @Bindable var userPreferences = userPreferences
      List {
        Toggle(isOn: $userPreferences.supportSearch) {
          Text(verbatim: "Support Search")
        }
      }
      .navigationTitle(Text(verbatim: "Search Debug"))
      .navigationBarTitleDisplayMode(.inline)
    }
  }
}

#Preview("Search Debug", body: {
  NavigationStack {
    SettingsView.SearchDebugScreen()
  }
  .previewEnvironment()
})

#endif
