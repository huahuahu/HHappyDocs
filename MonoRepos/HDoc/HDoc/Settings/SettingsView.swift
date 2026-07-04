//
//  SettingsView.swift
//  HDoc
//
//  Created by tigerguo on 2023/12/29.
//

import HDocAppConstants
import HDocIAP
import HDocModel
import HFoundation
import HLocalization
import HUIComponent
import SwiftUI

@MainActor
struct SettingsView: View {
  @Environment(UserPreferences.self) private var userPreferences: UserPreferences
  @Environment(\.recordSubscriptionStatus) private var recordSubscriptionStatus: RecordSubscriptionStatus
//  @State private var navigationStore = NavigationStore()
  @Environment(AppRoute.self) private var appRoute

  var body: some View {
    @Bindable var userPreferences = userPreferences
    @Bindable var appRoute = appRoute
    NavigationStack(path: $appRoute.settingNavigationStore.path) {
      Form {
        Section {
          HThemePicker(theme: .init(get: {
            HTheme(userPreferences.theme)
          }, set: { newTheme in
            userPreferences.theme = HDocTheme(newTheme)
          }))
          AppLockCell(appLockEnabled: $userPreferences.appLockEnabled)
        }

        Section {
          HFeedBackCell(model: HFeedbackModel(appName: HDocString.appName))
          HVersionCell()
        }
        Section {
          PrivacyCell()
          RawDataExportCell()
          CloudDataCell()
          AllDataDeletionCell()
        }

        Section {
          RecordSubscriptionBuyCell()
          HDocIAPRestoreCell()
        }

        #if DEBUG
          Section {
            RawDataCell()
            ResetRecordSubscriptionPromotionShownCell()
            ResetRecordSubscriptionCell()
          } header: {
            Text(verbatim: "debug")
          }
        #endif
      }
      .navigationDestination(for: HDocNavigationTarget.self, destination: { target in
        target.getTargetView()
      })
      .navigationTitle(HLocalizedString.setting)
    }
    .environment(appRoute.settingNavigationStore)
  }
}

extension HTheme {
  init(_ hdocTheme: HDocTheme) {
    switch hdocTheme {
    case .auto:
      self = .auto
    case .dark:
      self = .dark
    case .light:
      self = .light
    }
  }
}

extension HDocTheme {
  init(_ hTheme: HTheme) {
    switch hTheme {
    case .auto:
      self = .auto
    case .dark:
      self = .dark
    case .light:
      self = .light
    }
  }
}

#Preview {
  SettingsView()
    .previewEnvironment()
}

#Preview("cn") {
  SettingsView()
    .previewEnvironment()
    .environment(\.locale, .cnMainland)
}
