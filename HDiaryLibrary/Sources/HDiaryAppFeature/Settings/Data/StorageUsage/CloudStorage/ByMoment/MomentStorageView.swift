//
//  MomentStorageView.swift
//  HDiary
//
//  Created by tigerguo on 2024/5/26.
//
// View storage by moment

#if os(iOS)

import HDiaryConstants
import HDiaryModel
import SwiftData
import SwiftUI

@MainActor
struct MomentStorageView: View {
  @Query(filter: #Predicate<Moment> { !$0.markedAsDelete }) private var moment: [Moment]
  @State private var sortOrder: SortOrder = .byMediaSize

  var body: some View {
    List(sortedMoment) { moment in
      NavigationLink(value: HDiaryDestination.momentStorageDetail(moment)) {
        MomentCell(moment: moment)
      }
    }
    .toolbar(content: {
      toolbarView
    })
    .navigationTitle(Text(DiaryStringKey.Data.StorageUsage.cloudStorageViewByMoment))
    .navigationBarTitleDisplayMode(.inline)
  }

  enum SortOrder: String, CaseIterable, Identifiable, Hashable {
    case byDate
    case byMediaSize

    var id: String { self.rawValue }

    var label: LocalizedStringResource {
      switch self {
      case .byDate:
        DiaryStringKey.Common.sortByTimestamp
      case .byMediaSize:
        DiaryStringKey.Common.sort
      }
    }

    var hDiarySymbol: HDiarySymbol {
      switch self {
      case .byDate:
        .calendar
      case .byMediaSize:
        .storageSize
      }
    }
  }

  var sortedMoment: [Moment] {
    switch sortOrder {
    case .byDate:
      moment.sorted { $0.timestamp > $1.timestamp }
    case .byMediaSize:
      moment.sorted { $0.getMediaStorageSize() > $1.getMediaStorageSize() }
    }
  }

  var toolbarView: some ToolbarContent {
    ToolbarItem(placement: .primaryAction) {
      Picker(selection: $sortOrder) {
        ForEach(SortOrder.allCases) { sortOrder in
          Label {
            Text(sortOrder.label)
          } icon: {
            Image(hDiarySymbol: sortOrder.hDiarySymbol)
          }
          .tag(sortOrder)
        }
      } label: {
        Label {
          Text(DiaryStringKey.Common.sort)
        } icon: {
          Image(hDiarySymbol: .sort)
        }
      }
      .pickerStyle(.menu)
    }
  }
}

private struct MomentCell: View {
  let moment: Moment
  @ScaledMetric private var momentPadding = 5.0

  var body: some View {
    if let mediaItems = moment.mediaItems, !mediaItems.isEmpty {
      VStack(alignment: .leading, spacing: momentPadding) {
        titleAndTimeLabel
        mediaIntoView(for: mediaItems)
      }
    }
  }

  private var titleAndTimeLabel: some View {
    HStack(alignment: .firstTextBaseline) {
      Text(moment.title)
        .lineLimit(1)
        .font(.body)
        .foregroundStyle(.primary)

      Text(moment.timestamp.formatted(date: .numeric, time: .omitted))
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
  }

  private func mediaIntoView(for mediaItems: [MediaItem]) -> some View {
    Text(DiaryStringKey.Data.StorageUsage.mediaItemStorageSummary(
      for: mediaItems.count,
      sizeInBytes: moment.getMediaStorageSize().formatted(.byteCount(style: .file))
    )
    )
    .font(.subheadline)
  }
}

#Preview { @MainActor in
  NavigationStack {
    MomentStorageView()
  }
  .previewEnvironment()
}

#endif
