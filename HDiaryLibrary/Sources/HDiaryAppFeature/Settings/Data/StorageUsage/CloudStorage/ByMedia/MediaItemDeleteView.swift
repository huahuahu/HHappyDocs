//
//  MediaItemDeleteView.swift
//  HDiary
//
//  Created by tigerguo on 2024/5/26.
//

#if os(iOS)

import HDiaryModel
import HUIComponent
import SwiftData
import SwiftUI

@MainActor
struct MediaItemDeleteView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(NavigationStore.self) private var navigationStore

  let mediaItem: MediaItem
  var body: some View {
    ScrollView {
      momentSection
      itemPreview
    }
    .padding()
    .toolbar(content: {
      toolbarContent
    })
  }

  @ToolbarContentBuilder
  private var toolbarContent: some ToolbarContent {
    ToolbarItem(placement: .primaryAction) {
      Button(role: .destructive, action: {
        deleteMediaItem()
      }, label: {
        Label(
          title: { Text(DiaryStringKey.Common.delete) },
          icon: { Image(hDiarySymbol: .trash) }
        )
      })
    }
  }

  @ViewBuilder
  private var momentSection: some View {
    if let moment = mediaItem.moment {
      GroupBox(label: Text(verbatim: "相关的乐事"), content: {
        HStack(content: {
          NavigationLink(value: HDiaryDestination.moment(moment, editEnabled: false)) {
            Text(moment.title)
          }
          Spacer()
        })
      })
    }
    else {
      EmptyView()
    }
  }

  @ViewBuilder
  private var itemPreview: some View {
    if let mediaItemAndThumbnail = MediaItemAndThumbnail(mediaItem: mediaItem) {
      GroupBox(label: Text(verbatim: "Preview"), content: {
        HMediaItemView(itemAndThumbail: mediaItemAndThumbnail)
      })
    }
    else {
      EmptyView()
    }
  }

  private func deleteMediaItem() {
    modelContext.delete(mediaItem)
    navigationStore.path.removeLast()
  }
}

#if DEBUG
  #Preview { @MainActor in
    let items = try? HDiaryContainer.inMemoryPreviewContainer.mainContext.fetch(FetchDescriptor<MediaItem>())
    let item = items?.first
    return NavigationStack {
      MediaItemDeleteView(mediaItem: item!)
    }.previewEnvironment()
  }
#endif

#endif
