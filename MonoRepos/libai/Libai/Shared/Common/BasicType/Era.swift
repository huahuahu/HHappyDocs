//
//  Era.swift
//  Libai
//
//  Created by tigerguo on 2023/3/11.
//

import CoreData
import Foundation

/// Era mapped from CoreData
final class CDEra: NSManagedObject, Managed {
  @NSManaged private(set) var id: Int
  @NSManaged private(set) var startYear: Int
  @NSManaged private(set) var endYear: Int

  /// 年号
  @NSManaged private(set) var name: String

  @NSManaged private(set) var isDeletedInCloud: Bool

  @NSManaged var empire: CDEmpire?

  static func insert(_ jsonEra: JSONEra, into moc: NSManagedObjectContext) {
    let cdEra: CDEra = moc.insertObject()
    cdEra.id = jsonEra.id
    cdEra.startYear = jsonEra.starYear
    cdEra.endYear = jsonEra.endYear
    cdEra.name = jsonEra.name
    cdEra.isDeletedInCloud = false

    moc.performChanges {}
  }

  func deleteInCloud() {
    isDeletedInCloud = true
  }

  func update(from local: JSONEra) {
    hAssertion(local.id == id, "Can only update for same unique id")
    startYear = local.starYear
    endYear = local.endYear
    name = local.name
    isDeletedInCloud = false
  }
}

// MARK: - Era

/// Era mapped from CDEra, used in SwiftUI
struct Era: Decodable, Equatable {
  let id: Int

  /// 年号
  let name: String
  let starYear: Int
  let endYear: Int
  let empire: String
}

extension Era {
  init(_ cdEra: CDEra) {
    self.init(
      id: cdEra.id,
      name: cdEra.name,
      starYear: cdEra.startYear,
      endYear: cdEra.endYear,
      empire: cdEra.empire?.templeName ?? ""
    )
  }
}
