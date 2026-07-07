//
//  RawData.swift
//  HDiary
//
//  Created by tigerguo on 2024/3/28.
//

#if os(iOS)

import Foundation
import HDiaryModel
import SwiftData
import SwiftUI

protocol RawData: SwiftData.PersistentModel, Encodable {
  var uuid: UUID { get }
  var debugInfoLabel: String { get }
  var creationDate: Date { get }

  static var supportedSortType: [RawDataSortOrder] { get }

  func compare(with: Self, by order: RawDataSortOrder) -> ComparisonResult

  var size: Int? { get }
}

extension RawData {
  var size: Int? { nil }
}

extension Moment: RawData {
  var debugInfoLabel: String { title }

  var creationDate: Date { timestamp }

  static var supportedSortType: [RawDataSortOrder] { [.createDate, .title] }

  func compare(with another: Moment, by order: RawDataSortOrder) -> ComparisonResult {
    switch order {
    case .createDate:
      return self.creationDate.compare(another.creationDate)
    case .title:
      return self.title.compare(another.title)
    case .size:
      return ComparisonResult.orderedSame
    }
  }
}

extension Participant: RawData {
  var debugInfoLabel: String { title }
  static var supportedSortType: [RawDataSortOrder] { [.createDate, .title] }

  func compare(with another: Participant, by order: RawDataSortOrder) -> ComparisonResult {
    switch order {
    case .createDate:
      return self.creationDate.compare(another.creationDate)
    case .title:
      return self.title.compare(another.title)
    case .size:
      return ComparisonResult.orderedSame
    }
  }
}

extension Tag: RawData {
  var debugInfoLabel: String { title }
  static var supportedSortType: [RawDataSortOrder] { [.createDate, .title] }

  func compare(with another: Tag, by order: RawDataSortOrder) -> ComparisonResult {
    switch order {
    case .createDate:
      return self.creationDate.compare(another.creationDate)
    case .title:
      return self.title.compare(another.title)
    case .size:
      return ComparisonResult.orderedSame
    }
  }
}

extension MediaItem: RawData {
  var debugInfoLabel: String {
    let mediaTypeStr = mediaType?.rawValue ?? ""

    let storageStr = totalSize.formatted(.byteCount(style: .file))
    return "\(mediaTypeStr) \(storageStr) \(self.pathExtension)"
  }

  var creationDate: Date {
    createDate
  }

  var totalSize: Int {
    data.count + (thumbnailData150px?.count ?? 0) + (thumbnailData500px?.count ?? 0) + (thumbnailData1000px?.count ?? 0)
  }

  static var supportedSortType: [RawDataSortOrder] { [.createDate, .size] }

  func compare(with another: MediaItem, by order: RawDataSortOrder) -> ComparisonResult {
    switch order {
    case .createDate:
      return self.creationDate.compare(another.creationDate)
    case .title:
      return .orderedSame
    case .size:
      return NSNumber(value: self.totalSize).compare(NSNumber(value: another.totalSize))
    }
  }

  var size: Int? { totalSize }
}

extension HappyImage: RawData {
  var debugInfoLabel: String {
    "\(data.count.formatted(.byteCount(style: .file)))"
  }

  static var supportedSortType: [RawDataSortOrder] { [.createDate, .size] }
  func compare(with another: HappyImage, by order: RawDataSortOrder) -> ComparisonResult {
    switch order {
    case .createDate:
      return self.creationDate.compare(another.creationDate)
    case .title:
      return .orderedSame
    case .size:
      return NSNumber(value: self.data.count).compare(NSNumber(value: another.data.count))
    }
  }

  var size: Int? { data.count }
}

enum RawDataDestination: CaseIterable, Identifiable {
  case moment
  case participant
  case tag
  case mediaItem
  case happyImage

  var infoLabel: String {
    String(describing: self)
  }

  var id: Self {
    self
  }

  @MainActor @ViewBuilder
  var destinationView: some View {
    switch self {
    case .moment:
      RawDataDetailView<Moment>()
    case .participant:
      RawDataDetailView<Participant>()
    case .tag:
      RawDataDetailView<Tag>()
    case .mediaItem:
      RawDataDetailView<MediaItem>()
    case .happyImage:
      RawDataDetailView<HappyImage>()
    }
  }
}

#endif
