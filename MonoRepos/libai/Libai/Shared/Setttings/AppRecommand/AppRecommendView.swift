//
//  AppRecommendView.swift
//  Libai
//
//  Created by tigerguo on 2024/3/7.
//

import Foundation
import StoreKit
import SwiftUI

extension SettingsView {
  @MainActor
  struct AppRecommendView: View {
    @State private var hAppToShow: HApps?
    var body: some View {
      ForEach(HApps.allCases) { hApp in
        HStack(content: {
          Button(hApp.label) {
            hAppToShow = hApp
          }
        })
      }
      .appStoreOverlay(isPresented: .init(get: {
        hAppToShow != nil
      }, set: { newValue, _ in
        if newValue == false {
          hAppToShow = nil
        }
      })) {
        SKOverlay.AppConfiguration(appIdentifier: hAppToShow?.appID ?? HApps.hdiary.appID, position: .bottom)
      }
    }
  }

  private enum HApps: CaseIterable, Identifiable {
    case clipmate
    case hdiary

    var id: Self {
      self
    }

    var label: String {
      switch self {
      case .clipmate:
        "剪切调试"
      case .hdiary:
        "快乐日记"
      }
    }

    var appID: String {
      switch self {
      case .clipmate:
        "6447276479"
      case .hdiary:
        "6470147729"
      }
    }
  }
}
