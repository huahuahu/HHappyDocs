//
//  Location.swift
//  Libai
//
//  Created by huahuahu on 2022/3/12.
//

import CoreData
import Foundation

// MARK: - CDLocation

/// Location mapped from CoreData
final class CDLocation: NSManagedObject {
  @NSManaged private(set) var uniqueName: String
  @NSManaged private(set) var displayName: String
  @NSManaged private(set) var currentName: String

  /// 纬度
  @NSManaged private(set) var latitude: Double
  /// 经度
  @NSManaged private(set) var longitude: Double
  @NSManaged private(set) var isDeletedInCloud: Bool

  @NSManaged var annals: Set<CDAnnal>?
  @NSManaged var poems: Set<CDPoem>?

  static func insert(_ location: Location, into moc: NSManagedObjectContext) {
    let cdLocation: CDLocation = moc.insertObject()
    cdLocation.uniqueName = location.uniqueName
    cdLocation.displayName = location.displayName
    cdLocation.currentName = location.currentName
    cdLocation.latitude = location.latitude
    cdLocation.longitude = location.longitude
    cdLocation.isDeletedInCloud = false

    moc.performChanges {}
  }

  func deleteInCloud() {
    isDeletedInCloud = true
  }
}

extension CDLocation: Managed {}

extension CDLocation {
  func update(from local: JSONLocation) {
    hAssertion(local.uniqueName == uniqueName, "Can only update for same unique name")
    displayName = local.displayName
    currentName = local.currentName
    latitude = local.longitude
    longitude = local.latitude
    isDeletedInCloud = false
  }

  static func insert(_ location: JSONLocation, into moc: NSManagedObjectContext) {
    let cdLocation: CDLocation = moc.insertObject()
    cdLocation.uniqueName = location.uniqueName
    cdLocation.displayName = location.displayName
    cdLocation.currentName = location.currentName
    cdLocation.latitude = location.longitude
    cdLocation.longitude = location.latitude
    cdLocation.isDeletedInCloud = false

    moc.performChanges {}
  }
}

// MARK: - Location

/// Location mapped from CDLocation, used in SwiftUI
struct Location: Decodable, Equatable, Hashable {
  let uniqueName: String
  let displayName: String
  let currentName: String
  /// 纬度
  let latitude: Double
  /// 经度
  let longitude: Double
}

#if DEBUG
  extension Location {
    static let 碎叶城 = Location(
      uniqueName: "碎叶城",
      displayName: "碎叶城",
      currentName: "中亚托克马克",
      latitude: 42.833333,
      longitude: 75.063333
    )
  }
#endif

extension Location {
  init(_ cdLocation: CDLocation) {
    self.init(
      uniqueName: cdLocation.uniqueName,
      displayName: cdLocation.displayName,
      currentName: cdLocation.currentName,
      latitude: cdLocation.latitude,
      longitude: cdLocation.longitude
    )
  }
}
