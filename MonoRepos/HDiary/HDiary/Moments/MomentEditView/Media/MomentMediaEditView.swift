//
//  MomentMediaEditView.swift
//  HDiary
//
//  Created by tigerguo on 2023/6/24.
//

import HDiaryConstants
import HDiaryModel
import HMedia
import HUIComponent
import PhotosUI
import QuickLook
import SwiftData
import SwiftUI

@MainActor
struct MomentMediaEditView: View {
  @Binding private var legacyImages: [HappyImage]
  @Binding private var mediaItems: [MediaItem]
  @ScaledMetric private var cellPaddings = 10.0
  @ScaledMetric private var cellSize = 100.0

  @State private var pickerItems: [PhotosPickerItem] = []

  @State private var isLoadingImage = false

  init(legacyImages: Binding<[HappyImage]>, mediaItems: Binding<[MediaItem]>) {
    self._legacyImages = legacyImages
    self._mediaItems = mediaItems
  }

  var body: some View {
    HStack {
      Spacer()
      HFlowLayout(itemSpace: cellPaddings, rowSpace: cellPaddings) {
        ForEach(legacyImages) { legacyImage in
          imageView(for: legacyImage)
        }

        ForEach(mediaItems) { item in
          imageView(for: item)
        }
        if isLoadingImage {
          ProgressView()
            .frame(width: cellSize, height: cellSize)
        }
        else {
          VStack {
            Spacer()

            PhotosPicker(
              selection: $pickerItems,
              selectionBehavior: .ordered,
              matching: .images,
              preferredItemEncoding: .current,
              photoLibrary: .shared()
            ) {
              HImagePickerDefaultLabel()
            }
            .onChange(of: pickerItems) { _, _ in
              if !pickerItems.isEmpty {
                onPhotoPickerItemsAdded(pickerItems)
              }
            }

            Spacer()
          }
          .frame(height: cellSize)
        }
      }
      Spacer()
    }
  }

  private func onPhotoPickerItemsAdded(_ pickerItems: [PhotosPickerItem]) {
    Task {
      defer {
        Task { @MainActor in
          self.pickerItems.removeAll(keepingCapacity: true)
          self.isLoadingImage = false
          Log.common.info("reset status")
        }
      }
      await MainActor.run {
        self.isLoadingImage = true
      }
      for pickerItem in pickerItems {
        do {
          let hMediaItem = try await pickerItem.loadTransferable(type: HMediaItem.self)

          if let hMediaItem {
            let thumbnailData150px: Data? = try? UIImage.downsample(imageData: hMediaItem.data, to: CGSize(width: 150, height: 150))
            let thumbnailData500px: Data? = try? UIImage.downsample(imageData: hMediaItem.data, to: CGSize(width: 500, height: 500))
            let thumbnailData1000px: Data? = try? UIImage.downsample(imageData: hMediaItem.data, to: CGSize(width: 1000, height: 1000))

            await MainActor.run {
              let mediaItem = MediaItem(
                data: hMediaItem.data,
                mediaType: MediaItem.MediaType(hMediaItem.type),
                pathExtension: hMediaItem.pathExtension,
                thumbnailData150px: thumbnailData150px ?? hMediaItem.data,
                thumbnailData500px: thumbnailData500px ?? hMediaItem.data,
                thumbnailData1000px: thumbnailData1000px ?? hMediaItem.data
              )
              mediaItems.append(mediaItem)
              Log.common.info("Success to add image \(pickerItem.itemIdentifier ?? "") to moment ,media id  \(mediaItem.uuid)")
            }
          }
          else {
            Log.common.error("Can't add image to moment because media result is nil ")
          }
        }
        catch {
          Log.common.error("Can't get image, error is \(error) ")
        }
      }
    }
  }

  @ViewBuilder
  private func imageView(for mediaItem: MediaItem) -> some View {
    if let image = mediaItem.thumbnailData1000px.flatMap({ UIImage(data: $0) }) {
      ImageCell(image: image, source: .mediaItem(mediaItem), onDelete: {
        withAnimation {
          mediaItems.removeAll { $0.uuid == mediaItem.uuid }
        }
      })
      .padding()
    }
    else {
      EmptyView()
    }
  }

  @ViewBuilder
  private func imageView(for legacyImage: HappyImage) -> some View {
    if let image = legacyImage.thumbnailData1000px.flatMap({ UIImage(data: $0) }) {
      ImageCell(image: image, source: .happyImage(legacyImage), onDelete: {
        withAnimation {
          legacyImages.removeAll { $0.uuid == legacyImage.uuid }
        }
      })
      .padding()
    }
    else {
      EmptyView()
    }
  }
}

@MainActor
private struct ImageCell: View {
  enum Source {
    case mediaItem(MediaItem)
    case happyImage(HappyImage)

    var data: Data {
      switch self {
      case .mediaItem(let mediaItem):
        mediaItem.data
      case .happyImage(let happyImage):
        happyImage.data
      }
    }

    var pathExtension: String {
      switch self {
      case .mediaItem(let mediaItem):
        mediaItem.pathExtension
      case .happyImage:
        "heic"
      }
    }
  }

  @ScaledMetric private var cellSize = 100.0
  @ScaledMetric private var deleteButtonPadding = 2
  private let source: Source
  fileprivate init(image: UIImage, source: Source, onDelete: @escaping () -> Void) {
    self.image = image
    self.onDelete = onDelete
    self.source = source
  }

  let image: UIImage
  let onDelete: () -> Void
  @State private var isPresenting = false
  @State private var localPath: URL?

  var body: some View {
    thumbnail
      .aspectRatio(contentMode: .fill)
      .frame(width: cellSize, height: cellSize)
      .clipped()
      .overlay(alignment: .topLeading) {
        Button(action: {
          onDelete()
        }, label: {
          Image(systemName: "minus")
            .symbolVariant(.circle)
            .symbolVariant(.fill)
            .foregroundStyle(Color.red)
        })
        // https://stackoverflow.com/a/58895725/2739854
        .buttonStyle(BorderlessButtonStyle())
        .padding([.top, .leading], deleteButtonPadding)
      }
      .onTapGesture {
        writToTempPath()
      }
      .quickLookPreview($localPath)
  }

  private func writToTempPath() {
    Task {
      let tempDirectory = URL.makeTempUrl().appending(path: "item")
      do {
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        let tempUrl = tempDirectory.appendingPathExtension(source.pathExtension)
        try source.data.write(to: tempUrl)
        await MainActor.run {
          localPath = tempUrl
          Log.common.trace("Write to \(tempUrl) succeed)")
        }
      }
      catch {
        Log.common.error("Write \(source.pathExtension) file failed \(error)")
      }
    }
  }

  @ViewBuilder
  private var thumbnail: some View {
    switch source {
    case .mediaItem(let mediaItem):
      MediaThumbnailView(mediaItem: mediaItem, size: .px500)
    case .happyImage(let happyImage):
      HappyImageThumbnailNail(happyImage: happyImage, size: .px500)
    }
  }
}

private extension MediaItem.MediaType {
  init(_ mediaType: HMediaType) {
    switch mediaType {
    case .image:
      self = .image
    case .gif:
      self = .gif
    case .movie:
      self = .video
    }
  }
}

#if DEBUG

  #Preview("image") {
    struct ImageCellPreview: View {
      @Query var mediaItems: [MediaItem]
      var body: some View {
        List(mediaItems) { mediaItem in
          ImageCell(image: mediaItem.thumbnailData1000px.flatMap { UIImage.fromData($0) }.unsafelyUnwrapped, source: .mediaItem(mediaItem)) {
            print(" tapped")
          }
        }
      }
    }

    return ImageCellPreview()
      .modelContainer(HDiaryContainer.inMemoryPreviewContainer)
  }

  #Preview("Add Image") {
    let container = HDiaryContainer.inMemoryPreviewContainer
    var mediaItems = TestImage.symbols[0 ..< 4].map {
      MediaItem.from(systemName: $0).unsafelyUnwrapped
    }
    return NavigationStack {
      Form {
        Section {
          MomentMediaEditView(legacyImages: .constant([]), mediaItems: .init(get: {
            mediaItems
          }, set: { newValue in
            mediaItems = newValue
          }))
        } header: {
          Text(verbatim: "demo")
        }
      }
      .navigationTitle(Text(verbatim: "demo"))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .automatic) {
          Text(verbatim: "demo")
        }
      }
    }
    .modelContainer(container)
  }
#endif
