//
//  TermOfUseCell.swift
//  HDiary
//
//  Created by tigerguo on 2024/3/10.
//

import Foundation
import HUIComponent
import SwiftUI

extension SettingsView {
  @MainActor
  struct UseTermCell: View {
    @State private var termOfUse = false
    let termOfUseUrl = "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
    var body: some View {
      if let url = URL(string: termOfUseUrl) {
        Button(action: {
          termOfUse = true
        }, label: {
          Label(
            title: { Text(DiaryStringKey.Data.termOfUseLabel) },
            icon: { Image(hDiarySymbol: .termOfUse) }
          )
        })
        .sheet(
          isPresented: $termOfUse,
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
  Form(content: {
    SettingsView.UseTermCell()
      .previewEnvironment()
  })
})
