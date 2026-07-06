//
//  MediaStorageView.swift
//  HDiary
//
//  Created by tigerguo on 2024/5/26.
//

import HDiaryModel
import HMedia
import HUIComponent
import SwiftData
import SwiftUI

@MainActor
struct MediaStorageView: View {
  @Query private var mediaItems: [MediaItem]
  var body: some View {
    MediaItemsStorageView(mediaItems: mediaItems)
  }
}

struct MediaItemsStorageView: View {
  let mediaItems: [MediaItem]
  @ScaledMetric private var itemSize = 100.0
  @ScaledMetric private var itemSpacing = 2.0
  @ScaledMetric private var cornerRadius = 10.0
  var body: some View {
    Text(DiaryStringKey.Data.StorageUsage.mediaItemStorageSummary(for: mediaItems.count, sizeInBytes: itemStorageInByte.formatted(.byteCount(style: .file))))
      .foregroundStyle(.primary)
      .bold()
    ScrollView {
      LazyVGrid(columns: [GridItem(.adaptive(minimum: itemSize), spacing: itemSpacing)], spacing: itemSpacing, content: {
        ForEach(itemsBySize) { item in
          NavigationLink(value: HDiaryDestination.deleteMediaItem(mediaItem: item)) {
            MediaStorageInfoView(mediaItem: item)
              .frame(width: itemSize, height: itemSize)
              .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
          }
        }
      })
    }
    .scrollIndicators(.hidden)
    .padding()
  }

  private var itemStorageInByte: Int {
    mediaItems.reduce(into: 0) { result, mediaItem in
      result += mediaItem.storageSize ?? 0
    }
  }

  private var itemsBySize: [MediaItem] {
    mediaItems.sorted { ($0.storageSize ?? 0) > ($1.storageSize ?? 0) }
  }
}

#Preview { @MainActor in
  NavigationStack {
    MediaStorageView()
  }
  .previewEnvironment()
}
