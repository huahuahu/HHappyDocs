//
//  ChartEntryView.swift
//  HDiary
//
//  Created by tigerguo on 2023/9/3.
//

import SwiftUI

private struct CharEntryCell: View {
  let entry: ChartEntry

  var body: some View {
    Label {
      Text(capitalLocalized: entry.displayName)
    } icon: {
      Image(hDiarySymbol: entry.symbol)
    }
  }
}

struct ChartEntryView: View {
  var body: some View {
    List(ChartEntry.allCases) { entry in
      NavigationLink(value: HDiaryDestination.chartEntry(entry)) {
        CharEntryCell(entry: entry)
      }
    }
  }
}

#Preview {
  NavigationStack {
    ChartEntryView()
  }
}
