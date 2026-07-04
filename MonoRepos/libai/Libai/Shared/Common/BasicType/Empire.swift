//
//  Empire.swift
//  Libai
//
//  Created by tigerguo on 2023/3/4.
//

import CoreData
import Foundation

/// Empire mapped from CoreData
final class CDEmpire: NSManagedObject, Managed {
  /// 庙号, 唯一id
  @NSManaged private(set) var templeName: String
  @NSManaged private(set) var personalName: String

  /// 在位时间
  @NSManaged private(set) var reignFrom: Int
  @NSManaged private(set) var reignUntil: Int

  @NSManaged private(set) var birthYear: Int
  @NSManaged private(set) var deathYear: Int

  @NSManaged private(set) var isDeletedInCloud: Bool

  @NSManaged var eras: Set<CDEra>?

  static func insert(_ jsonEmpire: JSONEmpire, into moc: NSManagedObjectContext) {
    let cdEmpire: CDEmpire = moc.insertObject()
    cdEmpire.templeName = jsonEmpire.templeName
    cdEmpire.personalName = jsonEmpire.personalName
    cdEmpire.reignFrom = jsonEmpire.reignFrom
    cdEmpire.reignUntil = jsonEmpire.reignUntil
    cdEmpire.birthYear = jsonEmpire.birthYear
    cdEmpire.deathYear = jsonEmpire.deathYear

    cdEmpire.isDeletedInCloud = false

    moc.performChanges {}
  }

  func update(from local: JSONEmpire) {
    hAssertion(local.templeName == templeName, "Can only update for same unique templeName")
    personalName = local.personalName
    reignFrom = local.reignFrom
    reignUntil = local.reignUntil
    birthYear = local.birthYear
    deathYear = local.deathYear
    isDeletedInCloud = false
  }

  func deleteInCloud() {
    isDeletedInCloud = true
  }
}

// MARK: - Empire

/// Empire mapped from CDEmpire, used in SwiftUI
struct Empire: Decodable, Equatable {
  /// 庙号，唯一id
  let templeName: String
  let personalName: String
  let reignFrom: Int
  let reignUntil: Int
  let birthYear: Int
  let deathYear: Int
}

extension Empire {
  init(_ cdEmpire: CDEmpire) {
    self.init(
      templeName: cdEmpire.templeName,
      personalName: cdEmpire.personalName,
      reignFrom: cdEmpire.reignFrom,
      reignUntil: cdEmpire.reignUntil,
      birthYear: cdEmpire.birthYear,
      deathYear: cdEmpire.deathYear
    )
  }
}
