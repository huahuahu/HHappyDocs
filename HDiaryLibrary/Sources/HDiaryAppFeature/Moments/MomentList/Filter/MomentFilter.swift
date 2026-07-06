//
//  MomentFilter.swift
//  HDiary
//
//  Created by tigerguo on 2024/12/5.
//
#if os(iOS)

import Foundation
import HDiaryModel

enum MomentFilter: CaseIterable, Sendable, Hashable, Identifiable {
  case weekends
  case hasMedia

  var title: LocalizedStringResource {
    switch self {
    case .weekends:
      return DiaryStringKey.Moment.Filter.weekend
    case .hasMedia:
      return DiaryStringKey.Moment.Filter.hasMedia
    }
  }

  var id: Self {
    self
  }

  func isMatched(moment: Moment) -> Bool {
    switch self {
    case .weekends:
      return moment.isWeekend
    case .hasMedia:
      return moment.hasMedia
    }
  }
}

private extension Moment {
  var isWeekend: Bool {
    let calendar = Calendar.current
    return calendar.isDateInWeekend(timestamp)
  }

  var hasMedia: Bool {
    if let mediaItems, !mediaItems.isEmpty {
      return true
    }
    return false
  }
}

#endif
