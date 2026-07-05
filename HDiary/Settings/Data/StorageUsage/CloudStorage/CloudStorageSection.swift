//
//  CloudStorageSection.swift
//  HDiary
//
//  Created by tigerguo on 2024/5/26.
//

import HDiaryConstants
import HDiaryModel
import SwiftData
import SwiftUI

extension StorageUsageView {
  @MainActor struct CloudStorageSection: View {
    @Query private var mediaItems: [MediaItem]
    var body: some View {
      Section {
        LabeledContent {
          Text(totalMediaStorageSize.formatted(.byteCount(style: .file)))
        } label: {
          Text(DiaryStringKey.Data.StorageUsage.cloudStorageLabel)
        }

        NavigationLink(value: HDiaryDestination.storageByMoment) {
          Text(DiaryStringKey.Data.StorageUsage.cloudStorageViewByMoment)
        }
        NavigationLink(value: HDiaryDestination.storageByMedia) {
          Text(DiaryStringKey.Data.StorageUsage.cloudStorageViewByMedia)
        }
      } footer: {
        Text(DiaryStringKey.Data.StorageUsage.cloudStorageDescription)
      }
    }

    private var totalMediaStorageSize: Int {
      mediaItems.reduce(into: 0) { partialResult, mediaItem in
        partialResult += mediaItem.storageSize ?? 0
      }
    }
  }
}

#Preview { @MainActor in
  NavigationStack {
    Form {
      StorageUsageView.CloudStorageSection()
    }
  }
  .previewEnvironment()
}
