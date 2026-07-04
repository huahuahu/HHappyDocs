//
//  Annal.swift
//  Libai
//
//  Created by tigerguo on 2023/3/4.
//

import CoreData
import Foundation

/// Annal mapped from CoreData
final class CDAnnal: NSManagedObject, Managed {
  @NSManaged private(set) var id: Int
  @NSManaged private(set) var age: Int
  @NSManaged private(set) var content: String
  @NSManaged private(set) var summary: String
  @NSManaged private(set) var isDeletedInCloud: Bool

  @NSManaged var locations: Set<CDLocation>?

  @NSManaged var poems: Set<CDPoem>?

  static func insert(_ jsonAnnal: JSONAnnal, into moc: NSManagedObjectContext) {
    let cdAnnal: CDAnnal = moc.insertObject()
    cdAnnal.id = jsonAnnal.id
    cdAnnal.age = jsonAnnal.age
    cdAnnal.content = jsonAnnal.content
    cdAnnal.summary = jsonAnnal.summary
    cdAnnal.isDeletedInCloud = false

    moc.performChanges {}
  }

  func update(from local: JSONAnnal) {
    hAssertion(local.id == id, "Can only update for same id")
    id = local.id
    age = local.age
    content = local.content
    summary = local.summary
    isDeletedInCloud = false
  }

  func deleteInCloud() {
    isDeletedInCloud = true
  }
}

// MARK: - Annal

/// mapped from CDAnnal, used in SwiftUI
struct Annal: Decodable, Identifiable, Equatable {
  let id: Int
  let age: Int
  let content: String
  let locationIDs: [String]
  let summary: String?
}

#if DEBUG
  extension Annal {
    static let demo = Annal(
      id: 1,
      age: 1,
      content: "",
      locationIDs: [],
      summary: ""
    )
  }
#endif

extension Annal {
  init(_ cdAnnal: CDAnnal) {
    self.init(
      id: cdAnnal.id,
      age: cdAnnal.age,
      content: cdAnnal.content,
      locationIDs: cdAnnal.locations?.map(\.uniqueName) ?? [],
      summary: cdAnnal.summary
    )
  }
}
