//
//  TagChartView.swift
//  HDiary
//
//  Created by tigerguo on 2023/9/3.
//

#if os(iOS)

import Charts
import HDiaryModel
import SwiftData
import SwiftUI

private struct InnerTagChart: View {
  init(timeRange: Range<Date>, tagSortOrder: TagSortOrder) {
    self.timeRange = timeRange
    self.tagSortOrder = tagSortOrder
  }

  @ScaledMetric private var lineHeight = 40.0
  @Query private var tags: [Tag]

  let timeRange: Range<Date>
  let tagSortOrder: TagSortOrder

  var body: some View {
    Chart(sortedTags) { tag in
      let moments = tag.moments?.filter { timeRange.contains($0.timestamp) } ?? []
      BarMark(
        x: .value(Text(capitalLocalized: DiaryStringKey.count), moments.count),
        y: .value(Text(capitalLocalized: DiaryStringKey.tagEntryLabel), tag.title)
      )
      .annotation(position: .trailing) {
        Text(moments.count.formatted(.number))
          .font(.caption2)
          .monospacedDigit()
      }
    }
//    .chartYAxis {
//      AxisMarks(preset: .aligned, position: .leading)
//    }
    .frame(height: Double(sortedTags.count) * lineHeight)
  }

  private var sortedTags: [Tag] {
    struct TagWithMomentCount {
      let tag: Tag
      let momentCount: Int
    }

    let tagWithMomentCounts: [TagWithMomentCount] = tags.map { tag in
      TagWithMomentCount(
        tag: tag,
        momentCount: tag.moments?.filter { timeRange.contains($0.timestamp) }.count ?? 0
      )
    }
    .filter { $0.momentCount > 0 }

    switch tagSortOrder {
    case .name:
      return tagWithMomentCounts.sorted {
        if $0.tag.text.localizedStandardCompare($1.tag.text) == .orderedAscending {
          return true
        }
        return $0.momentCount > $1.momentCount
      }.map(\.tag)

    case .momentCount:
      return tagWithMomentCounts.sorted {
        if $0.momentCount == $1.momentCount {
          return $0.tag.text.localizedStandardCompare($1.tag.text) == .orderedAscending
        }
        return $0.momentCount > $1.momentCount
      }.map(\.tag)
    }
  }
}

@MainActor struct TagChartView: View {
  @State private var timeRangeEntry: TimeRangeEntry = .week
  @State private var customTimeRange: Range<Date> = TimeRangePickerView.defaultRange
  @State private var tagSortOrder: TagSortOrder = .name

  @Query(filter: #Predicate<Moment> { !$0.markedAsDelete }, sort: [SortDescriptor<Moment>(\.timestamp, order: .reverse)]) private var moments: [Moment]

  private var momentsForChart: [Moment] {
    return moments.filter { timeRange.contains($0.timestamp) }
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
          .listSectionSeparator(.hidden)
      }
      else {
        InnerTagChart(timeRange: timeRange, tagSortOrder: tagSortOrder)
          .listSectionSeparator(.hidden)
        itemsLink
          .listSectionSeparator(.hidden)
      }
    }
    .toolbar(content: {
      toolbarContent
    })

    .listStyle(.plain)
    .navigationTitle(Text(capitalLocalized: ChartEntry.tag.displayName))
  }

  private var itemsLink: some View {
    Section {
      NavigationLink(value: HDiaryDestination.timeConstrainedMoments(TimeConstrainedMoments(moments: momentsForChart, timeRangeString: timeRangeString))) {
        Text(capitalLocalized: DiaryStringKey.moments)
      }
    }
  }

  @ToolbarContentBuilder
  private var toolbarContent: some ToolbarContent {
    if !momentsForChart.isEmpty {
      ToolbarItem(placement: .primaryAction) {
        TagSortMenu { newTagSortOrder in
          tagSortOrder = newTagSortOrder
        }
      }
    }
  }
}

#Preview("no empty") {
  NavigationStack {
    TagChartView()
      .hDiaryNavigator()
  }
  .modelContainer(HDiaryContainer.inMemoryPreviewContainer)
}

#Preview("empty") {
  NavigationStack {
    TagChartView()
      .hDiaryNavigator()
  }
  .modelContainer(HDiaryContainer.inMemoryEmptyPreviewContainer)
}

#endif
