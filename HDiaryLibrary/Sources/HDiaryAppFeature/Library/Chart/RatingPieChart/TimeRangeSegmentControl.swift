//
//  TimeRangeSegmentControl.swift
//  HDiary
//
//  Created by tigerguo on 2023/8/30.
//

#if os(iOS)

import HFoundation
import SwiftUI

enum TimeRangeEntry: CaseIterable, Identifiable {
  var id: String {
    displayName
  }

  case week
  case month
  case custom

  var displayName: String {
    switch self {
    case .week:
      "week"
    case .month:
      "month"
    case .custom:
      "custom"
    }
  }

  var timeRange: Range<Date> {
    var dateComponent = DateComponents()
    let daysInBetween: Int
    switch self {
    case .week:
      daysInBetween = -6
    case .month:
      daysInBetween = -29
    case .custom:
      daysInBetween = -60
    }
    dateComponent.day = daysInBetween
    let now = Date()
    var date = Date()
    if let date1 = Calendar.current.date(byAdding: dateComponent, to: now) {
      date = date1
    }
    else {
      date = now.addingTimeInterval(-Double(daysInBetween) * 24 * 3600)
    }
    date = Calendar.current.startOfDay(for: date)
    return date ..< (Calendar.current.endOfDay(for: now) ?? now)
  }

  var displayNameRelativeToNow: LocalizedStringResource {
    switch self {
    case .week:
      DiaryStringKey.Library.Chart.timeRangeForLastDays(7)
    case .month:
      DiaryStringKey.Library.Chart.timeRangeForLastDays(30)
    case .custom:
      DiaryStringKey.Library.Chart.customTimeRange
    }
  }
}

struct TimeRangeSegmentControl: View {
  @Binding var timeRange: TimeRangeEntry
  var body: some View {
    Picker(selection: $timeRange.animation(.easeInOut), label: EmptyView()) {
      ForEach(TimeRangeEntry.allCases) { range in
        Text(range.displayNameRelativeToNow).tag(range)
      }
    }
    .pickerStyle(.segmented)
    .sensoryFeedback(.selection, trigger: timeRange)
  }
}

#Preview {
  var range = TimeRangeEntry.week
  return List {
    TimeRangeSegmentControl(timeRange: .init(get: {
      range
    }, set: { new, _ in
      range = new
    }))
  }
}

#endif
