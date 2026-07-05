//
//  MomentStorageDetailScreen.swift
//  HDiary
//
//  Created by tigerguo on 2024/9/30.
//
// Moment's media storage detail

import HDiaryModel
import SwiftData
import SwiftUI

@MainActor
struct MomentStorageDetailScreen: View {
  let moment: Moment

  @ScaledMetric var paddingBeforeSummary = 6.0
  @ScaledMetric var paddingAfterSummary = 5.0
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 0) {
        Text(moment.title)
          .font(.title)
          .bold()

        mediaSummaryView
          .padding(.top, paddingBeforeSummary)
          .padding(.bottom, paddingAfterSummary)

        mediaItemsPageView
      }
      .padding()
    }
  }

  @ViewBuilder
  private var mediaSummaryView: some View {
    if let mediaItems = moment.mediaItems, !mediaItems.isEmpty {
      Text(DiaryStringKey.Data.StorageUsage.mediaItemStorageSummary(for: mediaItems.count, sizeInBytes: moment.getMediaStorageSize().formatted(.byteCount(style: .file))))
    }
  }

  @ViewBuilder
  private var mediaItemsPageView: some View {
    if let mediaItems = moment.mediaItems, !mediaItems.isEmpty {
      TabView {
        ForEach(mediaItems) { mediaItem in
          MediaStorageInfoView(mediaItem: mediaItem)
            .frame(maxWidth: .infinity)
        }
      }
      .tabViewStyle(.page)
      .indexViewStyle(.page(backgroundDisplayMode: .always))
      .frame(maxWidth: .infinity, minHeight: 500)
    }
  }
}

private struct PreviewContainerView: View {
  @Query private var moments: [Moment]
  var body: some View {
    if let moment = moments.first(where: { $0.mediaItems?.isEmpty == false }) {
      MomentStorageDetailScreen(moment: moment)
    }
    else {
      EmptyView()
    }
  }
}

#Preview {
  NavigationStack {
    PreviewContainerView()
  }
  .previewEnvironment()
}
