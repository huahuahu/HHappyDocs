//
//  SettingsView.swift
//  Libai
//
//  Created by huahuahu on 2021/12/25.
//

import HUIComponent
import SwiftUI

@MainActor
struct SettingsView: View {
  @EnvironmentObject var settings: Settings
  @EnvironmentObject var navigationModel: HNavigationModel

  var body: some View {
    NavigationStack(path: $navigationModel.settingsPath) {
      Form {
        #if DEBUG

          Toggle(isOn: $settings.useDebugUrlForWeb) {
            Label("调试webview", systemImage: "network")
          }
          .toggleStyle(SwitchToggleStyle(tint: .accentColor))

          NavigationLink {
            LifeSpanChartsView(lifeSpans: [.libai, .武则天])
          } label: {
            Label("Debug View", systemImage: "ant.fill")
          }
          DBCell()
          NavigationLink {
            EraDebugView()
          } label: {
            Label("Era data", systemImage: "ant.fill")
          }

        #endif
        ThemePicker(theme: $settings.theme)
//        ClearCacheCell()
        WidgetCell()

        Section {
          HVersionCell()
          FeedbackCell()
        }

        Section("其他应用") {
          AppRecommendView()
        }
      }
      .hNavigationDestination()
      .navigationTitle("设置")
    }
  }
}

struct Settings_Previews: PreviewProvider {
  static var previews: some View {
    SettingsView().environmentObject(Settings.shared)
      .environmentObject(HNavigationModel())
  }
}
