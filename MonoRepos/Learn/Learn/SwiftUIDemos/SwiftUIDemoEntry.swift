//
//  SwiftUIDemoEntry.swift
//  Learn
//
//  Created by tigerguo on 2024/11/20.
//

import Foundation
import SwiftUI

enum SwiftUIDemo {}

extension SwiftUIDemo {
  enum SwiftUIDemoEntry: CaseIterable, Identifiable, Hashable {
    case sortOrderSelection
    case contextMenu
    case search
    case keyboardToolbar
    case alertEnvironment

    var id: Self {
      self
    }

    var title: String {
      switch self {
      case .sortOrderSelection:
        return "Sort Order Selection"
      case .contextMenu:
        return "Context Menu"
      case .search:
        return "Search"
      case .keyboardToolbar:
        return "Keyboard Toolbar"
      case .alertEnvironment:
        return "show Alert as environment"
      }
    }

    @MainActor
    @ViewBuilder var entryView: some View {
      switch self {
      case .sortOrderSelection:
        SortOrderDemoView()
      case .contextMenu:
        ContextMenuDemoView()
      case .search:
        SearchDemoView()
      case .keyboardToolbar:
        KeyboardToolBarDemoView()
      case .alertEnvironment:
        AlertDemoScreen()
          .withAlert()
      }
    }
  }
}
