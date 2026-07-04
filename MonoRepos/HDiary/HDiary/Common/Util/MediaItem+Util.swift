//
//  MediaItem+Util.swift
//  HDiary
//
//  Created by tigerguo on 2024/4/3.
//

import Foundation
import HDiaryModel
import HMedia
import HUIComponent
import UIKit

extension MediaItemAndThumbnail {
  init?(mediaItem: MediaItem) {
    let thumbnailData = mediaItem.thumbnailData1000px ?? mediaItem.data
    guard let thumbnail = UIImage.fromData(thumbnailData) else {
      return nil
    }
    self.init(data: mediaItem.data, pathExtension: mediaItem.pathExtension, thumbnail: thumbnail)
  }

  init?(happyImage: HappyImage) {
    let thumbnailData = happyImage.thumbnailData1000px ?? happyImage.data
    guard let thumbnail = UIImage.fromData(thumbnailData) else {
      return nil
    }
    self.init(data: happyImage.data, pathExtension: "heic", thumbnail: thumbnail)
  }
}
