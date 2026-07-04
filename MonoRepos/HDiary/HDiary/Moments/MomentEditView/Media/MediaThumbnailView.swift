//
//  MediaThumbnailView.swift
//  HDiary
//
//  Created by tigerguo on 2023/12/20.
//

import HDiaryModel
import HMedia
import SwiftData
import SwiftUI

@MainActor
struct MediaThumbnailView: View {
  enum Size {
    case px150
    case px500
    case px1000
  }

  let mediaItem: MediaItem
  let size: Size

  var body: some View {
    if let image = getImage() {
      Image(uiImage: image)
        .resizable()
    }
  }

  private func getImage() -> UIImage? {
    let imageData = switch size {
    case .px150:
      mediaItem.thumbnailData150px
    case .px500:
      mediaItem.thumbnailData500px
    case .px1000:
      mediaItem.thumbnailData1000px
    }

    return imageData.flatMap { UIImage(data: $0) }
  }
}

#if DEBUG
  #Preview {
    struct MePreview: View {
      @Query private var mediaItems: [MediaItem]

      var body: some View {
        List {
          ForEach(mediaItems) { mediaItem in
            MediaThumbnailView(mediaItem: mediaItem, size: .px1000)
              .aspectRatio(contentMode: .fit)
              .frame(height: 100)
          }
        }
      }
    }

    return MePreview()
      .modelContainer(HDiaryContainer.inMemoryPreviewContainer)
  }
#endif
