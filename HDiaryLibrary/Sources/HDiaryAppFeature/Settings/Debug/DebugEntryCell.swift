//
//  DebugEntryCell.swift
//  HDiary
//
//  Created by tigerguo on 2024/3/28.
//

#if os(iOS)

import SwiftUI

extension SettingsView {
  @MainActor
  struct DebugEntryCell: View {
    var body: some View {
      NavigationLink(value: HDiaryDestination.debugView) {
        Label(
          title: { Text(verbatim: "Debug") },
          icon: { Image(hDiarySymbol: .bug) }
        )
      }
    }
  }
}

#Preview {
  List {
    SettingsView.DebugEntryCell()
  }
}

#endif
