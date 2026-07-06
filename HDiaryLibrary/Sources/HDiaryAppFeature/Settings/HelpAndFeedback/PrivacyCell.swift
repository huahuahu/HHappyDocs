//
//  PrivacyCell.swift
//  HDiary
//
//  Created by tigerguo on 2024/3/10.
//

import Foundation
import HDiaryConstants
import HUIComponent
import SwiftUI

extension SettingsView {
  @MainActor
  struct PrivacyPolicyCell: View {
    @State private var showPrivacy = false
    var body: some View {
      if let url = URL(string: AppConstants.privacyUrl) {
        Button(action: {
          showPrivacy = true
        }, label: {
          Label(
            title: { Text(DiaryStringKey.Data.privacyPolicyLabel) },
            icon: { Image(hDiarySymbol: .privacyPolicy) }
          )
        })
        .sheet(
          isPresented: $showPrivacy,
          content: {
            HSafariWebView(
              url: url,
              entersReaderIfAvailable: true,
              tintColor: UIColor(Color.accentColor)
            )
            .ignoresSafeArea()
          }
        )
      }
    }
  }
}

#Preview(body: { @MainActor in
  NavigationStack {
    Form(content: {
      SettingsView.PrivacyPolicyCell()
        .previewEnvironment()
    })
    .navigationTitle(Text(verbatim: "Settings"))
  }
})
