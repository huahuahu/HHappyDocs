//
//  ImageSelectionView.swift
//  SharedExifPackage
//
//  Created by tigerguo on 2025/3/7.
//

import PhotosUI
import SwiftUI

@MainActor
struct ImageSelectionView: View {
  @State private var selectedImageStore = SelectedImageStore()
  @State private var selectedPickerItems: [PhotosPickerItem] = []
  @State private var position = ScrollPosition(edge: .top)

  private let padding: CGFloat = 10
  var body: some View {
    ScrollView(.horizontal) {
      HStack(spacing: padding) {
        ForEach(selectedImageStore.imageItems) { imageItem in
          SelectedImageView(imageItem: imageItem) { _ in
            selectedImageStore.removeImageItem(for: imageItem.pickerItem)
            selectedPickerItems.removeAll { $0 == imageItem.pickerItem }
          }
          .id(imageItem.pickerItem)
          .containerRelativeFrame(.horizontal, alignment: .center) { length, axis in
            if axis == .horizontal {
              return length - padding
            }
            else {
              return length
            }
          }
        }
        PhotosPicker(
          selection: $selectedPickerItems,
          matching: .images,
          preferredItemEncoding: .current
        ) {
          PhotoPickerContent()
        }
        .containerRelativeFrame(.horizontal, alignment: .center) { length, axis in
          if axis == .horizontal {
            return length - padding
          }
          else {
            return length
          }
        }
      }
      .scrollTargetLayout()
    }
    .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
    .contentMargins(.horizontal, padding * 2)
    .scrollTargetBehavior(.viewAligned)
    .scrollPosition($position)
    .onChange(of: selectedPickerItems) {
      selectedImageStore.updatePickerItems(selectedPickerItems)
      if let firstItem = selectedPickerItems.first {
        position.scrollTo(id: firstItem)
      }
      else {
        position.scrollTo(edge: .leading)
      }
    }
    .environment(selectedImageStore)
  }
}

#Preview { @MainActor in
  ImageSelectionView()
}
