//
//  AboutCell.swift
//  HDiary
//
//  Created by tigerguo on 2024/4/13.
//

#if os(iOS)

import HDiaryConstants
import HFoundation
import SwiftUI

extension SettingsView {
  struct AboutCell: View {
    var body: some View {
      NavigationLink(value: HDiaryDestination.about) {
        Label(
          title: { Text(DiaryStringKey.AppInfo.about) },
          icon: { Image(hDiarySymbol: .about) }
        )
      }
    }
  }
}

#Preview("en") { @MainActor in
  NavigationStack {
    Form(content: {
      SettingsView.AboutCell()
    })
  }
  .environment(\.locale, .en)
}

#Preview("cn") { @MainActor in
  NavigationStack {
    Form(content: {
      SettingsView.AboutCell()
    })
  }
  .environment(\.locale, .cnMainland)
}

#endif
