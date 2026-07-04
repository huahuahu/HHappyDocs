//
//  PrivacyCell.swift
//  HDoc
//
//  Created by tigerguo on 2024/2/7.
//

import HDocAppConstants
import HUIComponent
import SwiftUI

extension SettingsView {
  @MainActor struct PrivacyCell: View {
    @State private var showPrivacy = false
    var body: some View {
      if let url = URL(string: AppConstants.privacyUrl) {
        Button(action: {
          showPrivacy = true
        }, label: {
          Label(
            title: { Text(HDocString.Privacy.privacyPolicyLabel) },
            icon: { Image(hdocSymbol: .privacyPolicy) }
          )
        })
        .sheet(
          isPresented: $showPrivacy,
          content: {
            HSafariWebView(
              url: url,
              entersReaderIfAvailable: true,
              tintColor: .accent
            )
            .ignoresSafeArea()
          }
        )
      }
    }
  }
}

#Preview {
  Form {
    SettingsView.PrivacyCell()
  }
}
