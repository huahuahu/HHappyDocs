//
//  Tag.swift
//  Libai
//
//  Created by tigerguo on 2023/3/4.
//

import CoreData
import Foundation

/// Tag mapped from CoreData
final class CDTag: NSManagedObject, Managed {
  @NSManaged private(set) var name: String

  @NSManaged private(set) var isDeletedInCloud: Bool
  @NSManaged var poems: Set<CDPoem>?

  static func insert(_ tag: String, into moc: NSManagedObjectContext) {
    let cdTag: CDTag = moc.insertObject()
    cdTag.name = tag
    cdTag.isDeletedInCloud = false

    moc.performChanges {}
  }

  func update(from local: JSONTag) {
    hAssertion(local.name == name, "Can only update for same tag name")
    isDeletedInCloud = false
  }

  func deleteInCloud() {
    isDeletedInCloud = true
  }
}
