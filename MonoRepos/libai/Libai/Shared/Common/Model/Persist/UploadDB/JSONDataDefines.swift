//
//  JSONDataDefines.swift
//  Libai
//
//  Created by tigerguo on 2023/3/4.
//

import CoreData
import Foundation

struct JSONLocation: JSONDBType {
  let uniqueName: String
  let displayName: String
  let currentName: String
  let latitude: Double
  let longitude: Double

  static let localFileName = "location"

  func insertCoreData(into moc: NSManagedObjectContext) {
    CDLocation.insert(self, into: moc)
  }

  func update(_ cdInstance: CDLocation) {
    cdInstance.update(from: self)
  }

  var id: String {
    uniqueName
  }
}

extension CDLocation: JSONTypeInCoreData {
  var jsonID: String {
    uniqueName
  }
}

struct JSONEra: JSONDBType {
  let id: Int
  let name: String
  let starYear: Int
  let endYear: Int
  let empire: String
  static let localFileName = "era"

  func insertCoreData(into moc: NSManagedObjectContext) {
    CDEra.insert(self, into: moc)
  }

  func update(_ cdInstance: CDEra) {
    cdInstance.update(from: self)
  }
}

extension CDEra: JSONTypeInCoreData {
  var jsonID: Int { id }
}

struct JSONEmpire: JSONDBType {
  let templeName: String
  let personalName: String
  let reignFrom: Int
  let reignUntil: Int
  let birthYear: Int
  let deathYear: Int

  static var localFileName = "empire"

  func insertCoreData(into moc: NSManagedObjectContext) {
    CDEmpire.insert(self, into: moc)
  }

  func update(_ cdInstance: CDEmpire) {
    cdInstance.update(from: self)
  }

  var id: String {
    templeName
  }
}

extension CDEmpire: JSONTypeInCoreData {
  var jsonID: String { templeName }
}

struct JSONAnnal: JSONDBType {
  let id: Int
  let age: Int
  let content: String
  let summary: String
  let locations: [String]

  static var localFileName = "annal"

  func insertCoreData(into moc: NSManagedObjectContext) {
    CDAnnal.insert(self, into: moc)
  }

  func update(_ cdInstance: CDAnnal) {
    cdInstance.update(from: self)
  }
}

extension CDAnnal: JSONTypeInCoreData {
  var jsonID: Int { id }
}

struct JSONPoem: JSONDBType {
  let id: Int
  let title: String
  let content: String
  let tags: [String]
  let appreciation: String?
  let age: Int?
  let plainChinese: String?
  let locations: [String]
  let genre: String

  static var localFileName = "poem"

  func insertCoreData(into moc: NSManagedObjectContext) {
    CDPoem.insert(self, into: moc)
  }

  func update(_ cdInstance: CDPoem) {
    cdInstance.update(from: self)
  }
}

extension CDPoem: JSONTypeInCoreData {
  var jsonID: Int {
    id
  }
}

struct JSONTag: JSONDBType {
  let name: String
  static let localFileName = "tag"

  var id: String {
    name
  }

  func insertCoreData(into moc: NSManagedObjectContext) {
    CDTag.insert(name, into: moc)
  }

  func update(_ cdInstance: CDTag) {
    cdInstance.update(from: self)
  }

  // TODO: Find out why it doesn't work
//  static func getLocalInstances() throws -> [Self] {
//    guard let url = Bundle.main.url(forResource: Self.localFileName, withExtension: "json") else {
//      throw JSONDBTyeError.localFileNotFound(fileName: Self.localFileName)
//    }
//
//    let data = try Data(contentsOf: url)
//
//    let names = try JSONDecoder().decode([String].self, from: data)
//    return names.map { JSONTag(name: $0) }
//  }
}

extension CDTag: JSONTypeInCoreData {
  var jsonID: String { name }
}

protocol JSONTypeInCoreData<ID>: NSManagedObject, Managed {
  /// A type representing the stable identity of the entity associated with
  /// an instance.
  associatedtype ID: Hashable

  /// The stable identity of the entity associated with this instance.
  var jsonID: Self.ID { get }
  func deleteInCloud()
}

//
// Cannot build interface type for term [JSONDBType:ID]
// Prefix term does not not have a nested type named ID: [JSONDBType]
// Property map entry: [JSONDBType] => { conforms_to: [JSONDBType Decodable] }

protocol JSONDBType: Decodable {
  associatedtype CDType: JSONTypeInCoreData<ID>
  associatedtype ID: Hashable

  static var localFileName: String { get }
  var id: Self.ID { get }

  func update(_ cdInstance: CDType)

  func insertCoreData(into moc: NSManagedObjectContext)
}

private enum JSONDBTyeError: Error {
  case localFileNotFound(fileName: String)
}

extension JSONDBType {
  static func getLocalInstances() throws -> [Self] {
    guard let url = Bundle.main.url(forResource: localFileName, withExtension: "json") else {
      throw JSONDBTyeError.localFileNotFound(fileName: localFileName)
    }

    let data = try Data(contentsOf: url)

    let localInstances = try JSONDecoder().decode([Self].self, from: data)
    return localInstances
  }

  func findRelatedCDInstance(from cdInstances: [Self.CDType]) -> Self.CDType? {
    cdInstances.first { $0.jsonID == id }
  }
}

extension JSONTypeInCoreData {
  static func getCountInCoreData(_ moc: NSManagedObjectContext) throws -> Int {
    let currentInstancesInCloud = try {
      let fetchRequest = Self.sortedFetchRequest(with: .alwayTrue)
      let instances = try moc.fetch(fetchRequest)
      return instances
    }()
    return currentInstancesInCloud.count
  }

  static func getCoreDataInstances(_ moc: NSManagedObjectContext) throws -> [Self] {
    let currentInstancesInCloud = try {
      let fetchRequest = Self.sortedFetchRequest(with: .alwayTrue)
      let instances = try moc.fetch(fetchRequest)
      return instances
    }()
    return currentInstancesInCloud
  }
}
