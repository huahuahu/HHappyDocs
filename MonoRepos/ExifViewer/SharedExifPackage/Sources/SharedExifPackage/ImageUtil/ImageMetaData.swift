//
//  ImageMetaData.swift
//  SharedExifPackage
//
//  Created by tigerguo on 2025/3/8.
//

import CoreImage
import CoreLocation
import Foundation

class ImageMetaData: Equatable {
  static func == (lhs: ImageMetaData, rhs: ImageMetaData) -> Bool {
    lhs.width == rhs.width
      && lhs.height == rhs.height
      && lhs.fileName == rhs.fileName
      && lhs.fileSizeInBytes == rhs.fileSizeInBytes
      && lhs.dateTimeOriginal == rhs.dateTimeOriginal
      && lhs.dateTimeDigitized == rhs.dateTimeDigitized
      && lhs.location == rhs.location
  }

  let width: MetadataField
  let height: MetadataField
  let dimension: MetadataField
  var fileName: MetadataField
  let fileSizeInBytes: MetadataField

  var dateTimeOriginal: MetadataField
  var dateTimeDigitized: MetadataField

  let location: MetadataField

  init(width: Int, height: Int, fileName: String, fileSizeInBytes: Int) {
    self.width = .width(width)
    self.height = .height(height)
    self.dimension = .dimension(width: width, height: height)
    self.fileName = .fileName(fileName)
    self.fileSizeInBytes = .fileSize(fileSizeInBytes)
    self.dateTimeOriginal = .dateTimeOriginal(nil)
    self.dateTimeDigitized = .dateTimeDigitized(nil)
    self.location = .location(nil)
  }

  init?(imageUrl: URL) {
    fileName = .fileName(imageUrl.lastPathComponent)
    do {
      let fileAttributes = try FileManager.default.attributesOfItem(atPath: imageUrl.path)
      guard let size = fileAttributes[.size] as? Int64 else {
        Log.common.error("Failed to get file size")
        return nil
      }
      fileSizeInBytes = .fileSize(Int(size))
    }
    catch {
      Log.common.error("Failed to get file size, error: \(error, privacy: .public)")
      return nil
    }

    guard let ciImage = CIImage(contentsOf: imageUrl) else {
      Log.common.error("Failed to create CIImage from url: \(imageUrl)")
      return nil
    }
    let properties = ciImage.properties

    guard let exif = properties[kCGImagePropertyExifDictionary as String] as? [String: Any] else {
      Log.common.error("Failed to get exif data")
      return nil
    }

    if let exifVersionData = exif[kCGImagePropertyExifVersion as String] as? [Int] {
      let exifVersionString = exifVersionData.map(String.init).joined(separator: ".") // 将版本号数组转为字符串
      Log.common.info("exifVersion: \(exifVersionString)")
    }
    else {
      Log.common.error("Failed to get exif version")
    }

    guard let width = exif[kCGImagePropertyExifPixelXDimension as String] as? Int else {
      Log.common.error("Failed to get width")
      return nil
    }
    self.width = .width(width)
    guard let height = exif[kCGImagePropertyExifPixelYDimension as String] as? Int else {
      Log.common.error("Failed to get height")
      return nil
    }
    self.height = .height(height)
    self.dimension = .dimension(width: width, height: height)

    self.dateTimeOriginal = .dateTimeOriginal(Self.getDateTimeOriginal(from: exif))
    self.dateTimeDigitized = .dateTimeDigitized(Self.getDateTimeDigitized(from: exif))
    self.location = .location(Self.getLocation(from: properties))
  }

  private static func getDateTimeOriginal(from exifDictionary: [String: Any]) -> ExifDateInfo? {
    guard var dateTimeOriginal = exifDictionary[kCGImagePropertyExifDateTimeOriginal as String] as? String else {
      return nil
    }
    dateTimeOriginal.append(" ")
    let timeZone: TimeZone
    if let offsetTimeOriginalString = exifDictionary[kCGImagePropertyExifOffsetTimeOriginal as String] as? String {
      dateTimeOriginal.append(offsetTimeOriginalString)
      timeZone = DateUtil.timeZone(from: offsetTimeOriginalString) ?? .current
    }
    else {
      dateTimeOriginal.append("+00:00")
      timeZone = .current
    }
    let date = DateFormatter.exifDateFormatter.date(from: dateTimeOriginal)
    if let date {
      return ExifDateInfo(date: date, timeZone: timeZone)
    }
    return nil
  }

  private static func getDateTimeDigitized(from exifDictionary: [String: Any]) -> ExifDateInfo? {
    guard var dateTimeDigitized = exifDictionary[kCGImagePropertyExifDateTimeDigitized as String] as? String else {
      return nil
    }

    dateTimeDigitized.append(" ")
    if let offsetTimeOriginalString = exifDictionary[kCGImagePropertyExifOffsetTimeDigitized as String] as? String {
      dateTimeDigitized.append(offsetTimeOriginalString)
    }
    else {
      dateTimeDigitized.append("+00:00")
    }

    if let date = DateFormatter.exifDateFormatter.date(from: dateTimeDigitized) {
      return ExifDateInfo(date: date, timeZone: .gmt)
    }
    return nil
  }

  private static func getLocation(from properties: [String: Any]) -> CLLocation? {
    guard let gpsDictionary = properties[kCGImagePropertyGPSDictionary as String] as? [String: Any] else {
      Log.common.info("No GPS data")
      return nil
    }
    guard let latitude = gpsDictionary[kCGImagePropertyGPSLatitude as String] as? Double,
          let longitude = gpsDictionary[kCGImagePropertyGPSLongitude as String] as? Double else {
      return nil
    }
    Log.common.info("latitude: \(latitude), longitude: \(longitude)")
    return CLLocation(latitude: latitude, longitude: longitude)
  }
}

extension ImageMetaData {
  @MainActor static let demo = ImageMetaData(width: 1000, height: 2000, fileName: "demo.jpg", fileSizeInBytes: 1000)
}

enum MetadataFileValue: Sendable, Hashable {
  case string(String)
  case int(Int)
  case dateInfo(ExifDateInfo)
  case location(CLLocation)

  var location: CLLocation? {
    if case let .location(location) = self {
      return location
    }
    return nil
  }

  var date: Date? {
    if case .dateInfo(let dateInfo) = self {
      return dateInfo.date
    }
    return nil
  }

  var exifDateInfo: ExifDateInfo? {
    if case .dateInfo(let dateInfo) = self {
      return dateInfo
    }
    return nil
  }
}

struct MetadataFieldCategory: OptionSet, Sendable, Hashable {
  let rawValue: Int

  static let basic = Self(rawValue: 1 << 0)

  static let location = Self(rawValue: 1 << 1)
  static let imageSettings = Self(rawValue: 1 << 2)
  static let timeStamps = Self(rawValue: 1 << 3)
}

struct MetadataField: Sendable, Equatable {
  let name: LocalizedStringResource
  let description: LocalizedStringResource
  let value: MetadataFileValue?
  let category: MetadataFieldCategory
  let displayText: String?

  static func width(_ width: Int) -> Self {
    Self(
      name: ExifString.MetaData.width,
      description: ExifString.MetaData.widthDescription,
      value: .int(width),
      category: [.basic, .imageSettings],
      displayText: width.formatted(.number.grouping(.never))
    )
  }

  static func height(_ height: Int) -> Self {
    Self(
      name: ExifString.MetaData.height,
      description: ExifString.MetaData.heightDescription,
      value: .int(height),
      category: [.basic, .imageSettings],
      displayText: height.formatted(.number.grouping(.never))
    )
  }

  static func fileName(_ fileName: String) -> Self {
    Self(
      name: ExifString.MetaData.fileName,
      description: ExifString.MetaData.fileNameDescription,
      value: .string(fileName),
      category: [.basic],
      displayText: fileName
    )
  }

  static func fileSize(_ fileSize: Int) -> Self {
    Self(
      name: ExifString.MetaData.size,
      description: ExifString.MetaData.sizeDescription,
      value: .int(fileSize),
      category: [.basic],
      displayText: fileSize.formatted(.byteCount(style: .file))
    )
  }

  static func dimension(width: Int, height: Int) -> Self {
    let stringValue = "\(width.formatted(.number.grouping(.never))) x \(height.formatted(.number.grouping(.never)))"
    return Self(
      name: ExifString.MetaData.dimension,
      description: ExifString.MetaData.dimensionDescription,
      value: .string(stringValue),
      category: [.basic, .imageSettings],
      displayText: stringValue
    )
  }

  static func dateTimeOriginal(_ date: ExifDateInfo?) -> Self {
    Self(
      name: ExifString.MetaData.dateTimeOriginal,
      description: ExifString.MetaData.dateTimeOriginalDescription,
      value: date.map { .dateInfo($0) },
      category: [.basic, .timeStamps],
      displayText: date.map { $0.date.formatted() }
    )
  }

  static func dateTimeDigitized(_ date: ExifDateInfo?) -> Self {
    Self(
      name: ExifString.MetaData.dateTimeDigitized,
      description: ExifString.MetaData.dateTimeDigitizedDescription,
      value: date.map { .dateInfo($0) },
      category: [.basic, .timeStamps],
      displayText: date.map { $0.date.formatted() }
    )
  }

  static func location(_ location: CLLocation?) -> Self {
    Self(
      name: ExifString.MetaData.location,
      description: ExifString.MetaData.locationDescription,
      value: location.map { .location($0) },
      category: [.basic, .location],
      displayText: location.map { $0.description }
    )
  }
}
