//
//  ExifRemovalUtil.swift
//  SharedExifPackage
//
//  Created by tigerguo on 2025/3/9.
//
#if os(iOS)

  import ImageIO
  import MobileCoreServices
  import UIKit

  enum ExifRemovalUtil {
    static func removeExif(from inputURL: URL, outputURL: URL) throws (ExifRemovalError) {
      guard let imageSource = CGImageSourceCreateWithURL(inputURL as CFURL, nil),
            let imageType = CGImageSourceGetType(imageSource),
            let image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
        Log.common.error("Failed to load image")
        throw ExifRemovalError.failedToLoadImage
      }

      guard let destination = CGImageDestinationCreateWithURL(outputURL as CFURL, imageType, 1, nil) else {
        Log.common.error("Failed to create destination")
        throw ExifRemovalError.failedToCreateDestination
      }

      // 保存图像时不包含任何元数据
      CGImageDestinationAddImage(destination, image, nil)

      if CGImageDestinationFinalize(destination) {
        Log.common.info("Successfully removed Exif from image")
      }
      else {
        Log.common.error("Failed to write image")
        throw ExifRemovalError.failedToWriteImage
      }
    }
  }

  extension ExifRemovalUtil {
    enum ExifRemovalError: Error {
      case failedToLoadImage
      case failedToCreateDestination
      case failedToWriteImage

      var errorCode: Int {
        switch self {
        case .failedToLoadImage:
          return 1
        case .failedToCreateDestination:
          return 2
        case .failedToWriteImage:
          return 3
        }
      }
    }
  }

#endif
