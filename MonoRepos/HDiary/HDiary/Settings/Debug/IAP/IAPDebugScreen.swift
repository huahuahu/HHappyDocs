//
//  IAPDebugScreen.swift
//  HDiary
//
//  Created by tigerguo on 2025/4/30.
//

import HDiaryConstants
import SwiftUI

extension SettingsView {
  @MainActor
  struct IAPDebugScreen: View {
    @Environment(UserPreferences.self) private var userPreferences
    var body: some View {
      @Bindable var userPreferences = userPreferences
      List {
        Toggle(isOn: $userPreferences.bypassIPRestriction) {
          Text(verbatim: "Bypass IAP Restriction")
        }
      }
      .navigationTitle(Text(verbatim: "IAP Debug"))
      .navigationBarTitleDisplayMode(.inline)
    }
  }
}

#Preview("IAP Debug", body: {
  NavigationStack {
    SettingsView.IAPDebugScreen()
  }
  .previewEnvironment()
})
