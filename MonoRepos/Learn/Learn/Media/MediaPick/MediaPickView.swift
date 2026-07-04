//
//  MediaPickView.swift
//  Learn
//
//  Created by tigerguo on 2023/11/12.
//

import HMedia
import OSLog
import PhotosUI
import SwiftUI

@MainActor
struct MediaPickView: View {
  init() {}

  enum SelectedMedia {
    case loading
    case loaded(item: HMediaItem)
    case loadFailed
  }

  @State private var photoPickerItems: [PhotosPickerItem] = []
  @State private var isShowingPhotoPicker = false
//  @State private var mediaItems: [MediaItem] = []
  @State private var selectedMedias: [SelectedMedia] = []
  @State private var previousTask: Task<Void, Error>?
  var body: some View {
    ScrollView {
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 0) {
          ForEach((0 ..< selectedMedias.count), id: \.self, content: { index in
            mediaView(for: selectedMedias[index])
              .containerRelativeFrame(.horizontal, count: 1, span: 1, spacing: 0)
          })
        }
      }
      .scrollTargetBehavior(.paging)
      .photosPicker(
        isPresented: $isShowingPhotoPicker,
        selection: $photoPickerItems,
        maxSelectionCount: 4,
        selectionBehavior: .ordered,
        matching: .any(of: [.images, .videos]),
        preferredItemEncoding: .automatic,
        photoLibrary: .shared()
      )
      .onChange(of: photoPickerItems) { _, _ in
        onPhotoPickerItemsChange()
      }
    }
    .toolbar(content: {
      toolBar
    })
  }

  @ViewBuilder
  private func mediaView(for item: SelectedMedia) -> some View {
    switch item {
    case .loading:
      ProgressView {
        Text("loading")
      }
    case .loaded(let item):
      VStack {
        MediaItemview(mediaItem: item)
        VStack {
          Text(item.type.rawValue)
        }
      }

    case .loadFailed:
      Text(verbatim: "failed")
    }
  }

  @ToolbarContentBuilder
  private var toolBar: some ToolbarContent {
    ToolbarItemGroup(placement: .primaryAction) {
      Button(action: {
        isShowingPhotoPicker = true
      }, label: {
        Image(systemName: "photo.badge.plus")
      })
    }
  }

  private func onPhotoPickerItemsChange() {
    let processingItems = photoPickerItems

    selectedMedias = Array(repeating: .loading, count: photoPickerItems.count)
    Log.common.info("selected \(photoPickerItems.count) items, \(photoPickerItems.map { $0.supportedContentTypes.description }.joined(separator: "\n"))")
//    photoPickerItems.removeAll()
    Log.common.info("start processing selected photos \(processingItems.count)")
    previousTask?.cancel()
    previousTask = Task {
      var index = 0
      for pickerItem in processingItems {
        defer {
          index += 1
        }
        Log.common.info("start process item \(pickerItem.itemIdentifier ?? "")")
        if Task.isCancelled {
          Log.common.info("cancelled process item ")
          continue
        }
        do {
          var item = try await pickerItem.loadTransferable(type: HMediaItem.self)
          if Task.isCancelled {
            Log.common.info("cancelled process item ")
            continue
          }
          item?.identifier = pickerItem.itemIdentifier
          if let item {
            await MainActor.run {
              withAnimation {
                var tmp = selectedMedias
                tmp[index] = .loaded(item: item)
                selectedMedias = tmp
              }
            }

            Log.common.info("process item \(pickerItem.itemIdentifier ?? "") success!")
          }
          else {
            await MainActor.run {
              var tmp = selectedMedias
              tmp[index] = .loadFailed
              selectedMedias = tmp
            }

            Log.common.error("faile to get media item for \(pickerItem.itemIdentifier ?? "")")
          }
        }
        catch {
          await MainActor.run {
            var tmp = selectedMedias
            tmp[index] = .loadFailed
            selectedMedias = tmp
          }

          Log.common.error("faile to get media item for \(pickerItem.itemIdentifier ?? "") with error \(error)")
        }
      }
    }
  }
}

#Preview {
  MediaPickView()
}
