//
//  InteractionEntry.swift
//  Learn
//
//  Created by tigerguo on 2023/11/14.
//

import Foundation
import SwiftUI

enum InteractionEntry: String, RawRepresentable, Hashable, CaseIterable, Identifiable {
  case dragDropText
  case dragDropMediaItem
  case journalSuggestionDemo = "Journal Suggestion Demo"

  var id: String {
    rawValue
  }
}

extension InteractionEntry {
  @MainActor
  @ViewBuilder func destination() -> some View {
    switch self {
    case .dragDropText:
      TextDragView()
    case .dragDropMediaItem:
      MediaItemDragDropView()

    case .journalSuggestionDemo:
      JournalDemoScreen()
    }
  }
}
