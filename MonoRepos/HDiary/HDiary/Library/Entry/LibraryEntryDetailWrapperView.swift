//
//  LibraryEntryDetailWrapperView.swift
//  HDiary
//
//  Created by tigerguo on 2023/6/18.
//

import SwiftUI

struct LibraryEntryDetailWrapperView: View {
  let entry: LibraryEntry
  var body: some View {
    switch entry {
    case .tag:
      AllTagsView()
    case .participant:
      AllParticipantsView()
    case .chart:
      ChartEntryView()
    }
  }
}

#Preview {
  LibraryEntryDetailWrapperView(entry: .chart)
}
