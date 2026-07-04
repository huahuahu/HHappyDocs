//
//  UIImage+Util.swift
//
//
//  Created by tigerguo on 2023/12/9.
//

import Foundation
#if canImport(UIKit)
  import UIKit
  import UniformTypeIdentifiers

  public enum HImageError: Error {
    case createImageSourceFromDataFail
    case getThumbnailFromImageSourceFail
    case createImageDestinationFail
    case originalDataNotImage
    case getImageSizeFail
  }

  public extension UIImage {
    static func fromData(_ data: Data) -> UIImage? {
      let imageReader: UIImageReader = {
        var config = UIImageReader.Configuration()
        config.prefersHighDynamicRange = true
        return UIImageReader(configuration: config)
      }()

      return imageReader.image(data: data) ?? UIImage(data: data)
    }

    /// Downsample image data. Can run in any thread
    /// - Parameters:
    ///   - imageData: image data to downsample
    ///   - size: Size in pixel
    /// - Returns: Downsampled UIImage
    static func downsample(imageData: Data, to size: CGSize) throws -> UIImage {
      guard let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil) else {
        throw HImageError.createImageSourceFromDataFail
      }

      // 从 CGImageSource 中获取图像属性
      let options: [NSString: Any] = [
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceShouldCacheImmediately: true,
        kCGImageSourceThumbnailMaxPixelSize: max(size.width, size.height),
      ]

      // Check whether need downsample based on size comparation
      if let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, options as CFDictionary) as? [NSString: Any],
         let originalWidth = properties[kCGImagePropertyPixelWidth] as? CGFloat,
         let originalHeight = properties[kCGImagePropertyPixelHeight] as? CGFloat,
         originalWidth < size.width,
         originalHeight < size.height {
        let image = CGImageSourceCreateImageAtIndex(imageSource, 0, options as CFDictionary)
        if let image {
          return UIImage(cgImage: image)
        }
        else {
          throw HImageError.originalDataNotImage
        }
      }

      guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else {
        throw HImageError.getThumbnailFromImageSourceFail
      }

      // 创建 UIImage 对象
      let downsampledImage = UIImage(cgImage: thumbnail)
      return downsampledImage
    }

    /// Downsample image data. Can run in any thread
    /// - Parameters:
    ///   - imageData: image data to downsample
    ///   - size: Size in pixel
    /// - Returns: Downsampled image data
    static func downsample(imageData: Data, to size: CGSize) throws -> Data {
      guard let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil) else {
        throw HImageError.createImageSourceFromDataFail
      }

      // 从 CGImageSource 中获取图像属性
      let options: [NSString: Any] = [
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceShouldCacheImmediately: true,
        kCGImageSourceThumbnailMaxPixelSize: max(size.width, size.height),
      ]

      // Check whether need downsample based on size comparation
      if let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, options as CFDictionary) as? [NSString: Any],
         let originalWidth = properties[kCGImagePropertyPixelWidth] as? CGFloat,
         let originalHeight = properties[kCGImagePropertyPixelHeight] as? CGFloat,
         originalWidth < size.width,
         originalHeight < size.height {
        return imageData
      }

      guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else {
        throw HImageError.getThumbnailFromImageSourceFail
      }

      let data = NSMutableData()
      guard let imageDestination = CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil) else {
        throw HImageError.createImageDestinationFail
      }

      let isPNG: Bool = {
        guard let utType = thumbnail.utType else { return false }
        return (utType as String) == UTType.png.identifier
      }()

      let destinationProperties = [
        kCGImageDestinationLossyCompressionQuality: isPNG ? 1.0 : 0.75,
      ] as CFDictionary

      CGImageDestinationAddImage(imageDestination, thumbnail, destinationProperties)
      CGImageDestinationFinalize(imageDestination)
      return Data(data)
    }

    static func imageSize(for imageData: Data) throws -> CGSize {
      guard let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil) else {
        throw HImageError.createImageSourceFromDataFail
      }

      // 从 CGImageSource 中获取图像属性
      let options: [NSString: Any] = [
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceShouldCacheImmediately: true,
      ]

      // get original size
      guard let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, options as CFDictionary) as? [NSString: Any],
            let originalWidth = properties[kCGImagePropertyPixelWidth] as? CGFloat,
            let originalHeight = properties[kCGImagePropertyPixelHeight] as? CGFloat
      else {
        throw HImageError.getImageSizeFail
      }

      return CGSize(width: originalWidth, height: originalHeight)
    }
  }

#endif
