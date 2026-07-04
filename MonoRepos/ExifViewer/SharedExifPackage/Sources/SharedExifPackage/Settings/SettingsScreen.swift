//
//  SettingsScreen.swift
//  SharedExifPackage
//
//  Created by tigerguo on 2025/3/7.
//

import HUIComponent
import SwiftUI

@MainActor
struct SettingsScreen: View {
  var body: some View {
    NavigationStack {
      Form {
        versionCell
        feedbackCell
      }
      .navigationTitle(Text(ExifString.Common.settings.hDocLocalized()))
    }
  }

  @ViewBuilder
  private var versionCell: some View {
    HVersionCell()
  }

  @ViewBuilder
  private var feedbackCell: some View {
    HFeedBackCell(model: HFeedbackModel(appName: AppConstant.appName))
  }
}

#Preview { @MainActor in
  SettingsScreen()
}
