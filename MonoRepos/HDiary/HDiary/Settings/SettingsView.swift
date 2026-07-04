//
//  SettingsView.swift
//  HDiary
//
//  Created by tigerguo on 2023/3/17.
//

import HDiaryConstants
import HDiaryIAP
import HDiaryModel
import HLocalization
import HUIComponent
import SwiftUI

@MainActor
struct SettingsView: View {
  init(isSelected: Binding<Bool>) {
    self._isSelected = isSelected
  }

  @Environment(UserPreferences.self) private var userPreferences: UserPreferences

  @Binding var isSelected: Bool
  @Environment(HDiaryRoute.self) private var appRoute

  var body: some View {
    @Bindable var userPreferences = userPreferences
    @Bindable var appRoute = appRoute
    NavigationStack(path: $appRoute.settingNavigationStore.path) {
      Form(content: {
        Section {
          HThemePicker(theme: $userPreferences.theme)
          LocalNotifictionConfigCell()
          AppLockCell(appLockEnabled: $userPreferences.appLockEnabled)
        }

        Section {
          ExportDataCell()
          DateUsageCell()
          CloudDataCell()
        }
        Section {
          RecordSubscriptionBuyCell()
          HDiaryIAPRestoreCell()
        }

        Section {
          HelpAndFeedbackCell()
        }
        #if DEBUG
          Section {
            DebugEntryCell()
          }
        #endif
      })
      .onOpenURL { url in
        if self.isSelected {
          Log.Navigation.common.info("handle url in setting tab")
          appRoute.settingNavigationStore.handle(url)
        }
      }
      .navigationDestination(for: HDiaryDestination.self) { destination in
        destination.targetView
      }
//      .withSheetDestinations(sheetDestinations: $navigationStore.presentedSheet)
      .navigationTitle(HLocalizedString.setting)
    }
    .environment(appRoute.settingNavigationStore)
//    .onAppear {
//      navigationStore.path.append(HDiaryDestination.debugView)
//      navigationStore.path.append(HDiaryDestination.debugEntry(entry: .rawData))
//    }
  }
}

#Preview("en") {
  SettingsView(isSelected: .constant(true))
    .previewEnvironment()
    .environment(UserPreferences.shared)
}

#Preview("cn") {
  SettingsView(isSelected: .constant(true))
    .previewEnvironment()
    .environment(UserPreferences.shared)
}
