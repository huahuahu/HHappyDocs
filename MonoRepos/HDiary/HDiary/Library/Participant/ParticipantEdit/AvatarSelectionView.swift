//
//  AvatarSelectionView.swift
//  HDiary
//
//  Created by tigerguo on 2023/6/26.
//

import HDiaryConstants
import HDiaryModel
import HUIComponent
import PhotosUI
import SwiftUI

@MainActor
struct AvatarSelectionView: View {
  @State private var item: PhotosPickerItem?
  @Binding var image: UIImage?
  @State private var hasNewSelectedImage = false

  @ScaledMetric private var size = Design.Avatar.size

  init(image: Binding<UIImage?>) {
    self._image = image
  }

  var body: some View {
    PhotosPicker(
      selection: $item,
      matching: .images,
      preferredItemEncoding: .current
    ) {
      AvatarImageView(size: size, image: image ?? UIImage(resource: .defaultPerson))
    }
    .onChange(of: item) { _, newItem in
      if let newItem {
        Task {
          do {
            let photo = try await newItem.loadTransferable(type: HPhoto.self)
            await MainActor.run {
              image = photo?.image
              hasNewSelectedImage = true
            }
          }
          catch {
            Log.common.error("Failed to pick avatar")
          }
        }
      }
    }
    .sheet(isPresented: $hasNewSelectedImage, content: {
      cropView(for: image ?? UIImage(resource: .defaultPerson))
    })
  }

  @ViewBuilder
  func cropView(for image: UIImage) -> some View {
    HImageCropper(
      originalImage: image,
      imageSize: .init(width: 300, height: 300),
      onCropFinish: { image in
        Task { @MainActor in
          self.image = image
          item = nil
        }
      }
    )
  }
}

#Preview {
  AvatarSelectionView(image: .init(get: {
    .add
  }, set: { _ in
    print("new Image")
  }))
}
