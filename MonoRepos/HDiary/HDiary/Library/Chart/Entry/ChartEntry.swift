//
//  ChartEntry.swift
//  HDiary
//
//  Created by tigerguo on 2023/9/3.
//

import Foundation
import HDiaryConstants
import HDiaryModel

enum ChartEntry: CaseIterable, Identifiable {
  case rating
  case tag

  var displayName: LocalizedStringResource {
    switch self {
    case .rating:
      return DiaryStringKey.chartEntryByRating
    case .tag:
      return DiaryStringKey.chartEntryByTag
    }
  }

  var symbol: HDiarySymbol {
    switch self {
    case .rating:
      return .star
    case .tag:
      return .tag
    }
  }

  var id: Self {
    self
  }
}
