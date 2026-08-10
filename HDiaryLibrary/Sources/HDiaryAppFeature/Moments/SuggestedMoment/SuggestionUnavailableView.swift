//
//  SuggestionUnavailableView.swift
//  HDiary
//
//  Created by tigerguo on 2024/12/23.
//

#if os(iOS)

import Foundation
import HDiaryConstants
import SwiftUI

@MainActor
struct SuggestionUnavailableView: View {
  var body: some View {
    ScrollView {
      ContentUnavailableView {
        Text(DiaryStringKey.Moment.Add.suggestionUnavailableTitle)
      } description: {
        Text(DiaryStringKey.Moment.Add.suggestionUnavailableDescription)
      }
    }
  }
}

#Preview { @MainActor in
  NavigationStack {
    SuggestionUnavailableView()
      .toolbar(content: {
        ToolbarItem(placement: .cancellationAction) {
          Button {
            Log.common.log(level: DiagnosticLogging.level(for: .info), "cancel button tapped")
          } label: {
            Text(verbatim: "Cancel")
          }
        }
      })
  }
}

#endif
