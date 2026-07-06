//
//  TimeRangePickerView.swift
//  HDiary
//
//  Created by tigerguo on 2025/1/10.
//

#if os(iOS)

import HFoundation
import SwiftUI

@MainActor
struct TimeRangePickerView: View {
  static let defaultRange: Range<Date> = Date().addingTimeInterval(-60 * 60 * 24 * 60) ..< Date()
  @State private var startDate = defaultRange.lowerBound
  @State private var endDate = Date()

  let onNewRange: (Range<Date>) -> Void
  init(onNewRange: @escaping (Range<Date>) -> Void) {
    self.onNewRange = onNewRange
  }

  var body: some View {
    VStack {
      // DatePickers for selecting the range
      DatePicker(selection: $startDate, displayedComponents: [.date]) {
        Text(DiaryStringKey.Library.Chart.startDate)
      }
      .onChange(of: startDate, initial: true) {
        updateDateRange()
      }
      DatePicker(selection: $endDate, in: startDate..., displayedComponents: [.date]) {
        Text(DiaryStringKey.Library.Chart.endDate)
      }
      .onChange(of: endDate, initial: true) {
        updateDateRange()
      }
    }
  }

  private func updateDateRange() {
    let firstOfStartDate = Calendar.current.startOfDay(for: startDate)
    let lastOfEndDate = Calendar.current.endOfDay(for: endDate) ?? endDate

    onNewRange(firstOfStartDate ..< lastOfEndDate)
  }

  private var dateRange: Range<Date> {
    startDate ..< endDate
  }
}

#Preview("Time Range Picker", body: {
  @Previewable @State var selectedDateRange: Range<Date> = Date() ..< Date().addingTimeInterval(60 * 60 * 24 * 7)
  NavigationStack {
    List {
      Text(selectedDateRange.formatted(.interval.day()))
      TimeRangePickerView { newRange in
        selectedDateRange = newRange
      }
    }
  }
})

#endif
