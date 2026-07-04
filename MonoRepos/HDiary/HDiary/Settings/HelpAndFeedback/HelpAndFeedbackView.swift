//
//  HelpAndFeedbackView.swift
//  HDiary
//
//  Created by tigerguo on 2024/5/25.
//

import HUIComponent
import SwiftUI

@MainActor
struct HelpAndFeedbackView: View {
  var body: some View {
    Form {
      Section {
        SettingsView.PrivacyPolicyCell()
        SettingsView.UseTermCell()
      }

      Section {
        HFeedBackCell(model: HFeedbackModel(appName: String(localized: "CFBundleDisplayName", table: "InfoPlist")))
        HVersionCell()
        SettingsView.AboutCell()
      }
    }
    .navigationTitle(Text(DiaryStringKey.Common.helpAndFeedback))
    .navigationBarTitleDisplayMode(.inline)
  }
}

#Preview { @MainActor in
  NavigationStack {
    HelpAndFeedbackView()
  }
}
