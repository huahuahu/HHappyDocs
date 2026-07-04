//
//  PhotoPickerContent.swift
//  SharedExifPackage
//
//  Created by tigerguo on 2025/3/7.
//

import PhotosUI
import SwiftUI

@MainActor
struct PhotoPickerContent: View {
  @ScaledMetric private var spacing: CGFloat = 20.0

  var body: some View {
    VStack(spacing: spacing) {
      Image(hExifSymbol: .addImage)
        .resizable()
        .scaledToFit()
        .symbolRenderingMode(.multicolor)
        .symbolVariant(.circle)
        .symbolVariant(.fill)
    }
    .padding(.horizontal)
    .accessibilityLabel(Text(ExifString.PhotoPicker.label.hDocLocalized()))
  }
}

#Preview { @MainActor in

  @Previewable @State var selectedItem: PhotosPickerItem?

  NavigationStack {
    ScrollView(.horizontal) {
      PhotosPicker(
        selection: $selectedItem,
        matching: .images
      ) {
        PhotoPickerContent()
      }
      .containerRelativeFrame(.horizontal, alignment: .center) { length, axis in
        if axis == .horizontal {
          return length - 10
        }
        else {
          return length
        }
      }
      .navigationTitle(Text(verbatim: "Demo"))
    }
  }
}
