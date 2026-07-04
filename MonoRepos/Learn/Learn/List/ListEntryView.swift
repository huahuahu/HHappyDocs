//
//  ListEntryView.swift
//  Learn
//
//  Created by tigerguo on 2023/12/21.
//

import SwiftUI

struct ListEntryView: View {
  var body: some View {
    List(ListEntry.allCases) { entry in
      NavigationLink(value: NavigationTarget.listEntry(entry: entry)) {
        Text(String(describing: entry))
      }
    }
  }
}

#Preview {
  ListEntryView()
}

enum ListEntry: Identifiable, Hashable, Equatable, CaseIterable {
  case scroll
  case plainScrollView

  var id: Self {
    self
  }
}

extension ListEntry {
  @MainActor
  @ViewBuilder func destination() -> some View {
    switch self {
    case .scroll:
      ListScrollDemoView()
    case .plainScrollView:
      PlainScrollDemoView()
    }
  }
}
