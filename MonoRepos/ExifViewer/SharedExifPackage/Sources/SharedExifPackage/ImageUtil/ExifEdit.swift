//
//  ExifEdit.swift
//  SharedExifPackage
//
//  Created by tigerguo on 2025/3/22.
//
import Foundation
import ImageIO
import MobileCoreServices

struct ExifEdit {
  func updateImageMetadata(sourceURL: URL, newMetaData: ImageMetaData) throws -> URL {
    // 1. 读取原始图像数据
    guard let imageSource = CGImageSourceCreateWithURL(sourceURL as CFURL, nil) else {
      Log.common.error("无法读取源文件")
      throw EditExifError.noSourceFile
    }

    // 2. 获取原始图像格式（如 JPEG、PNG）
    guard let utType = CGImageSourceGetType(imageSource) else {
      Log.common.error("无法识别图像格式")
      throw EditExifError.noImageSource
    }
    let pathExtension = sourceURL.pathExtension
    let originalName = sourceURL.deletingPathExtension().lastPathComponent
    let newName = "\(originalName)_\(UUID().uuidString)_edited"

    let destinationURL = sourceURL.deletingLastPathComponent().appendingPathComponent(newName).appendingPathExtension(pathExtension)

    // 3. 创建目标文件写入器
    guard let imageDestination = CGImageDestinationCreateWithURL(destinationURL as CFURL, utType, 1, nil) else {
      Log.common.error("无法创建目标文件")
      throw EditExifError.cannotCreateDestination
    }

    // 4. 获取原始元数据
//        CGImageSourceCopyMetadataAtIndex
    let metadata = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any] ?? [:]
    // 5. 合并新的 GPS 数据到元数据
    var newMetadata = metadata

    var exifDictionary = newMetadata[kCGImagePropertyExifDictionary as String] as? [String: Any] ?? [:]
    if let exifDateInfo = newMetaData.dateTimeOriginal.value?.exifDateInfo {
      let dateFormatter = DateFormatter.exifDateFormatter
      dateFormatter.timeZone = exifDateInfo.timeZone

      let newDateString = dateFormatter.string(from: exifDateInfo.date)
      Log.common.info("date: \(exifDictionary[kCGImagePropertyExifDateTimeOriginal as String] as? String ?? "") -> \(newDateString)")
      exifDictionary[kCGImagePropertyExifDateTimeOriginal as String] = newDateString
      Log.common.info("date: \(exifDictionary[kCGImagePropertyExifDateTimeDigitized as String] as? String ?? "") -> \(newDateString)")
      exifDictionary[kCGImagePropertyExifDateTimeDigitized as String] = newDateString
      Log.common.info("newDateString: \(newDateString)")
    }
    newMetadata[kCGImagePropertyExifDictionary as String] = exifDictionary
    // 6. 写入图像数据（保留原始数据，仅修改元数据）
    let targetProperties = [
      kCGImagePropertyExifDictionary as String: exifDictionary,
    ] as CFDictionary
    CGImageDestinationAddImageFromSource(imageDestination, imageSource, 0, targetProperties)
    // 7. 完成写入
    guard CGImageDestinationFinalize(imageDestination) else {
      Log.common.error("保存失败")
      throw EditExifError.cannotWrite
    }
//
    Log.common.info("修改metadata成功")
    Log.common.debug("new metadata: \(newMetadata), destinationURL: \(destinationURL)")
    return destinationURL
  }

  enum EditExifError: Error {
    case noSourceFile
    case noImageSource
    case cannotCreateDestination
    case cannotWrite
  }
}
