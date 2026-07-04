//
//  MomentRatingPieChartView.swift
//  HDiary
//
//  Created by tigerguo on 2023/8/30.
//

import Charts
import HDiaryModel
import HUIComponent
import SwiftData
import SwiftUI

private struct MomentPieChart: View {
  @ScaledMetric private var paddingAboveLegend = 18.0

  let moments: [Moment]
  let momentsByRating: [Int: [Moment]]

  @State var selectedAngle: Double?

  init(moments: [Moment]) {
    self.moments = moments
    self.momentsByRating =
      moments.reduce(into: [Int: [Moment]]()) { partialResult, moment in
        var cur = partialResult[moment.rating] ?? [Moment]()
        cur.append(moment)
        partialResult[moment.rating] = cur
      }
  }

  private var selectedRating: Int? {
    guard let selectedAngle else { return nil }
    var current = 0
    for key in momentsByRating.keys.sorted() {
      current += (momentsByRating[key]?.count ?? 0)
      if Double(current) >= selectedAngle {
        return key
      }
    }
    return nil
  }

  private func getOpacity(for rating: Int) -> Double {
    guard let selectedRating else {
      return 1.0
    }
    return selectedRating == rating ? 1 : 0.3
  }

  var body: some View {
    Chart {
      ForEach(momentsByRating.keys.sorted(), id: \.self) { key in
        SectorMark(
          angle: .value(Text(DiaryStringKey.count), momentsByRating[key]?.count ?? 0),
          innerRadius: .ratio(0.618),
          angularInset: 1.5
        )
        .cornerRadius(5.0)
        .foregroundStyle(by: .value(Text(DiaryStringKey.rating), charLegend(for: key)))
        .opacity(getOpacity(for: key))
      }
    }
    .chartAngleSelection(value: $selectedAngle)
    .chartLegend(alignment: .center, spacing: paddingAboveLegend)
    .scaledToFit()
    .chartBackground { chatProxy in
      GeometryReader { geometry in
        if let plotFrame = chatProxy.plotFrame {
          let frame = geometry[plotFrame]
          chartCenterView
            .position(x: frame.midX, y: frame.midY)
        }
      }
    }
  }

  private var chartCenterView: some View {
    VStack {
      if let selectedRating {
        let count = momentsByRating[selectedRating]?.count ?? 0
        Text(charLegend(for: selectedRating))
          .font(.title2.bold())
          .foregroundColor(.primary)
        Text(DiaryStringKey.momentLabelWithNumber(count))
          .font(.callout)
          .foregroundStyle(.secondary)
      }
      else {
        Text(DiaryStringKey.total)
          .font(.title2.bold())
          .foregroundColor(.primary)
        Text(DiaryStringKey.momentLabelWithNumber(moments.count))
          .font(.callout)
          .foregroundStyle(.secondary)
      }
    }
  }

  private func charLegend(for rating: Int) -> String {
    if rating == 0 {
      return String(localized: DiaryStringKey.unrated)
    }
    else {
      return String(localized: DiaryStringKey.textForRating(rating))
    }
  }
}

struct MomentRatingPieChartView: View {
  @State private var timeRangeEntry: TimeRangeEntry = .week
  @Query(filter: #Predicate<Moment> { !$0.markedAsDelete }, sort: [SortDescriptor<Moment>(\.timestamp, order: .reverse)]) private var moments: [Moment]
  @State var selectedAngle: Double? {
    didSet {
      print("selected rating \($selectedAngle)")
    }
  }

  @State private var customTimeRange: Range<Date> = TimeRangePickerView.defaultRange

  var body: some View {
    List {
      TimeRangeSegmentControl(timeRange: $timeRangeEntry)
        .listRowSeparator(.hidden)
      if timeRangeEntry == .custom {
        TimeRangePickerView { newRange in
          customTimeRange = newRange
        }
      }
      if momentsForChart.isEmpty {
        NoMomentView()
          .listRowSeparator(.hidden)
      }
      else {
        MomentPieChart(moments: momentsForChart)
        itemsLink
      }
    }
    .navigationTitle(Text(capitalLocalized: ChartEntry.rating.displayName))
    .listStyle(.plain)
  }

  private var timeRange: Range<Date> {
    switch timeRangeEntry {
    case .month:
      TimeRangeEntry.month.timeRange
    case .week:
      TimeRangeEntry.week.timeRange
    case .custom:
      customTimeRange
    }
  }

  private var timeRangeString: String {
    switch timeRangeEntry {
    case .month:
      return String(localized: TimeRangeEntry.month.displayNameRelativeToNow)
    case .week:
      return String(localized: TimeRangeEntry.week.displayNameRelativeToNow)
    case .custom:
      return customTimeRange.formatted(.interval.day().month().year())
    }
  }

  private var itemsLink: some View {
    Section {
      NavigationLink(value: HDiaryDestination.timeConstrainedMoments(TimeConstrainedMoments(moments: momentsForChart, timeRangeString: timeRangeString))) {
        Text(capitalLocalized: DiaryStringKey.moments)
      }
    }
  }

  var momentsForChart: [Moment] {
    return moments.filter { timeRange.contains($0.timestamp) }
  }
}

#Preview("no-empty") {
  NavigationStack {
    MomentRatingPieChartView()
      .hDiaryNavigator()
      .navigationTitle(Text(verbatim: "Title"))
  }
  .modelContainer(HDiaryContainer.inMemoryPreviewContainer)
}

#Preview("Empty") {
  NavigationStack {
    MomentRatingPieChartView()
      .hDiaryNavigator()
      .navigationTitle(Text(verbatim: "Title"))
  }
  .modelContainer(HDiaryContainer.inMemoryEmptyPreviewContainer)
}
