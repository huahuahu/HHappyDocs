//
//  AddMomentMenu.swift
//  HDiary
//
//  Created by tigerguo on 2024/12/23.
//

#if os(iOS)

import HDiaryConstants
import SwiftUI

@MainActor
struct AddMomentMenu: View {
  let addEmptyMoment: () -> Void
  let addMomentFromSuggestion: () -> Void

  var body: some View {
    if HDiaryUtil.isJournalingSuggestionsAvailable {
      menuWithSuggestion
    }
    else {
      addEmptyMomentButton
    }
  }

  @ViewBuilder
  private var menuWithSuggestion: some View {
    Menu {
      Button(action: addEmptyMoment) {
        Label(
          title: { Text(DiaryStringKey.Moment.Add.newFromEmpty) },
          icon: { Image(hDiarySymbol: .squareDashed) }
        )
      }
      Button(action: addMomentFromSuggestion) {
        Label(
          title: { Text(DiaryStringKey.Moment.Add.newFromSuggestion) },
          icon: { Image(hDiarySymbol: .lightbulb) }
        )
      }
    } label: {
      Label(
        title: { Text(DiaryStringKey.addMomentViewTitle) },
        icon: { Image(hDiarySymbol: .plus) }
      )
    } primaryAction: {
      addEmptyMoment()
    }
  }

  @ViewBuilder
  private var addEmptyMomentButton: some View {
    Button(action: addEmptyMoment) {
      Label(
        title: { Text(DiaryStringKey.addMomentViewTitle) },
        icon: { Image(hDiarySymbol: .plus) }
      )
    }
  }
}

#Preview { @MainActor in

  NavigationStack {
    Text(verbatim: "test")
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          AddMomentMenu(addEmptyMoment: {
            Log.common.info("add moment")
          }, addMomentFromSuggestion: {
            Log.common.info("add moment from suggestion")
          })
        }
      }
  }
}

#endif
