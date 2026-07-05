//
//  LibraryEntryCell.swift
//  HDiary
//
//  Created by tigerguo on 2023/6/18.
//

import Foundation
import SwiftUI

struct LibraryEntryCell: View {
  let entry: LibraryEntry

  var body: some View {
    Label {
      Text(entry.label)
    } icon: {
      Image(hDiarySymbol: entry.symbol)
    }
  }
}

#Preview {
  NavigationStack {
    List {
      NavigationLink(value: HDiaryDestination.libraryEntry(entry: .chart)) {
        LibraryEntryCell(entry: .chart)
      }
    }
  }
}
