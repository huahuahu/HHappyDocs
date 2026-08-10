//
//  HImagePicker.swift
//  HDiary
//
//  Created by tigerguo on 2023/6/23.
//

#if os(iOS)

import HDiaryConstants
import PhotosUI
import SwiftUI

struct HImagePickerConfig {
  let onNewItemAdded: (PhotosPickerItem) -> Void

  init(
    onNewItemAdded: @escaping (PhotosPickerItem) -> Void
  ) {
    self.onNewItemAdded = onNewItemAdded
  }
}

struct HImagePicker: View {
  @State private var item: PhotosPickerItem?

  let config: HImagePickerConfig

  init(config: HImagePickerConfig) {
    self.config = config
  }

  var body: some View {
    PhotosPicker(
      selection: $item,
      matching: .images,
      preferredItemEncoding: .current
    ) {
      HImagePickerDefaultLabel()
    }
    .onChange(of: item) { _, newItem in
      if let newItem {
        config.onNewItemAdded(newItem)
      }
    }
  }
}

extension HImagePickerConfig {
  static let demo = HImagePickerConfig(onNewItemAdded: { newItem in
    Log.common.log(
      level: DiagnosticLogging.level(for: .debug),
      "Preview selected a new item: \(String(describing: newItem))"
    )
  })
}

#Preview {
  HImagePicker(config: .demo)
}

#endif
