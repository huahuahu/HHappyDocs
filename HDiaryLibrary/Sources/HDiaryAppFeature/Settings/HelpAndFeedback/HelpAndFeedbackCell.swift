//
//  HelpAndFeedbackCell.swift
//  HDiary
//
//  Created by tigerguo on 2024/5/25.
//

#if os(iOS)

import HDiaryConstants
import HDiaryModel
import SwiftUI

extension SettingsView {
  struct HelpAndFeedbackCell: View {
    var body: some View {
      NavigationLink(value: HDiaryDestination.helpAndFeedback) {
        Label(
          title: { Text(DiaryStringKey.Common.helpAndFeedback) },
          icon: { Image(hDiarySymbol: .questionMark).symbolVariant(.circle) }
        )
      }
    }
  }
}

#Preview { @MainActor in
  NavigationStack {
    Form {
      SettingsView.HelpAndFeedbackCell()
    }
  }
}

#endif
