//
//  HappyImageThumbnailNail.swift
//  HDiary
//
//  Created by tigerguo on 2023/12/21.
//

import HDiaryModel
import HMedia
import SwiftData
import SwiftUI

@MainActor
struct HappyImageThumbnailNail: View {
  enum Size {
    case px150
    case px500
    case px1000
  }

  let happyImage: HappyImage
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
      happyImage.thumbnailData150px
    case .px500:
      happyImage.thumbnailData500px
    case .px1000:
      happyImage.thumbnailData1000px
    }

    return imageData.flatMap { UIImage(data: $0) }
  }
}
