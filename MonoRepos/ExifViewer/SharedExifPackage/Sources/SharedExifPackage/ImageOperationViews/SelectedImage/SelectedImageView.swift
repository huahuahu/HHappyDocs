//
//  SelectedImageView.swift
//  SharedExifPackage
//
//  Created by tigerguo on 2025/3/7.
//
#if os(iOS)

  import PhotosUI
  import SwiftUI
  import UIKit

  @MainActor
  struct SelectedImageView: View {
    @Environment(SelectedImageStore.self) var selectedImageStore
    init(imageItem: ImageItem, onRemove: @escaping (ImageItem) -> Void) {
      self.imageItem = imageItem
      self.onRemove = onRemove
    }

    let imageItem: ImageItem
    let onRemove: (ImageItem) -> Void

    var body: some View {
      Group {
        switch imageItem.loadState {
        case .loading:
          ProgressView()
        case .loadError(let error):
          Text(error)
            .textSelection(.enabled)
        case .loaded(let fileImage, let uiImage):
          successViewFor(uiImage: uiImage, fileImage: fileImage)
        }
      }
      .scrollTransition(axis: .horizontal) { effect, phase in
        effect.scaleEffect(x: phase.isIdentity ? 1.0 : 0.8, y: phase.isIdentity ? 1.0 : 0.8)
      }
    }

    @ViewBuilder
    func successViewFor(uiImage: UIImage, fileImage: FileImage) -> some View {
      SuccessView(uiImage: uiImage, fileImage: fileImage) {
        onRemove(imageItem)
      }
    }
  }

  extension SelectedImageView {
    @MainActor
    struct SuccessView: View {
      let uiImage: UIImage
      let fileImage: FileImage
      let onRemove: () -> Void
      @ScaledMetric var padding: CGFloat = 10

      var body: some View {
        ScrollView(.vertical) {
          VStack(spacing: padding) {
            ImageHeaderView(image: uiImage, imageUrl: fileImage.url) {
              onRemove()
            }
            if let metaData = ImageMetaData(imageUrl: fileImage.url) {
              ExifMetaDataView(imageMetaData: metaData)
            }

            ShareButton(url: fileImage.url)

            MetadataEditButton(url: fileImage.url)
          }
        }
      }
    }
  }
#endif
