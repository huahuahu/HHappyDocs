//
//  LibraryEntry.swift
//  HDiary
//
//  Created by tigerguo on 2023/6/18.
//

#if os(iOS)

import Foundation
import HDiaryConstants
import HDiaryModel

enum LibraryEntry: CaseIterable {
  case tag
  case participant
  case chart

  var label: LocalizedStringResource {
    switch self {
    case .tag:
      return DiaryStringKey.tagEntryLabel
    case .participant:
      return DiaryStringKey.participantEntryLabel
    case .chart:
      return DiaryStringKey.chart
    }
  }

  var symbol: HDiarySymbol {
    switch self {
    case .tag:
      return .tag
    case .participant:
      return .participant
    case .chart:
      return .chart
    }
  }
}

extension LibraryEntry: Identifiable {
  var id: LibraryEntry { self }
}

#endif
