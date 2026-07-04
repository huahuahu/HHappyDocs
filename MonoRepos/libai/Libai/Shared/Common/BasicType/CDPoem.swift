//
//  CDPoem.swift
//  Libai
//
//  Created by tigerguo on 2023/3/4.
//

import CoreData
import Foundation

final class CDPoem: NSManagedObject, Managed, Identifiable {
  @NSManaged private(set) var id: Int
  @NSManaged private(set) var title: String
  @NSManaged private(set) var content: String
  @NSManaged private(set) var appreciation: String?
  // Don't use Int? because compile error: "Property cannot be marked @NSManaged because its type cannot be represented in Objective-C"
  @NSManaged private var age: NSNumber?
  @NSManaged private(set) var plainChinese: String?
  @NSManaged private(set) var genre: String

  @NSManaged private(set) var isDeletedInCloud: Bool
  @NSManaged var locations: Set<CDLocation>?
  @NSManaged var tags: Set<CDTag>?
  @NSManaged var annal: CDAnnal?

  /// Cloudkit null become zero in local CoreData.
  /// This is a workaround
  /// https://github.com/huahuahu/libai/issues/121
  var actualAge: Int? {
    if let intAge = age?.intValue, intAge == 0 {
      return nil
    }
    return age?.intValue
  }

  static func insert(_ jsonPoem: JSONPoem, into moc: NSManagedObjectContext) {
    let cdPoem: CDPoem = moc.insertObject()
    cdPoem.id = jsonPoem.id
    cdPoem.title = jsonPoem.title
    cdPoem.content = jsonPoem.content
    cdPoem.appreciation = jsonPoem.appreciation
    cdPoem.age = jsonPoem.age as? NSNumber
    cdPoem.plainChinese = jsonPoem.plainChinese
    cdPoem.genre = jsonPoem.genre

    cdPoem.isDeletedInCloud = false

    moc.performChanges {}
  }

  func update(from local: JSONPoem) {
    hAssertion(local.id == id, "Can only update for same id")
    id = local.id
    title = local.title
    content = local.content
    appreciation = local.appreciation
    age = local.age as? NSNumber
    plainChinese = local.plainChinese
    genre = local.genre
    isDeletedInCloud = false
  }

  func deleteInCloud() {
    isDeletedInCloud = true
  }
}

extension Poem {
  init(_ cdPoem: CDPoem) {
    self.init(
      id: cdPoem.id,
      title: cdPoem.title,
      content: cdPoem.content,
      tags: (cdPoem.tags?.map(\.name) ?? []).sorted { $0.chineseCompare($1) == .orderedAscending },
      appreciation: cdPoem.appreciation,
      locationIds: (cdPoem.locations?.map(\.uniqueName) ?? []).sorted { $0.chineseCompare($1) == .orderedAscending },
      genre: cdPoem.genre,
      age: cdPoem.actualAge,
      plainChinese: cdPoem.plainChinese
    )
  }
}
