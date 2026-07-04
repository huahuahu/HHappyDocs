//
//  DBUploader.swift
//  Libai
//
//  Created by huahuahu on 2022/3/5.
//

import Foundation

struct DBUploader {
  let action: DBAaction

  func perform() {
    switch action {
    case .check:
      check()
    case .upload:
      upload()
    }
  }

  func check() {
    do {
      var count = try JSONEmpire.getLocalInstances().count
      hAssertion(count == 6, "Should have 6 empires")

      count = try JSONTag.getLocalInstances().count
      hAssertion(count == 78, "Should have 78 tags")

      count = try JSONLocation.getLocalInstances().count
      hAssertion(count == 81, "Should have 81 locations")

      count = try JSONEra.getLocalInstances().count
      hAssertion(count == 28, "Should have 28 CDEra")

      count = try JSONAnnal.getLocalInstances().count
      hAssertion(count == 62, "Should have 62 CDAnnal")

      count = try JSONPoem.getLocalInstances().count
      hAssertion(count == 990, "Should have 990 CDPoem")
      dataLog("check success")
    }
    catch {
      hAssertFailure("check  fail \(error)")
    }
  }

  func upload() {
    do {
      try update(JSONEmpire.self)
      try update(JSONTag.self)
      try update(JSONLocation.self)
      try update(JSONEra.self)
      try update(JSONAnnal.self)
      try update(JSONPoem.self)

      // Clean relations
      let moc = HCoreDataStack.shared.privateManagedContext

      let cdEmpires = try CDEmpire.getCoreDataInstances(moc)
      let cdTags = try CDTag.getCoreDataInstances(moc)
      let cdLocations = try CDLocation.getCoreDataInstances(moc)
      let cdEras = try CDEra.getCoreDataInstances(moc)
      let cdAnnals = try CDAnnal.getCoreDataInstances(moc)
      let cdPoems = try CDPoem.getCoreDataInstances(moc)

      let jsonEras = try JSONEra.getLocalInstances()
      let jsonAnnals = try JSONAnnal.getLocalInstances()
      let jsonPoems = try JSONPoem.getLocalInstances()

      moc.performChanges {
        for cdEra in cdEras {
          cdEra.empire = nil
        }
        for empire in cdEmpires {
          empire.eras = nil
        }

        for location in cdLocations {
          location.annals = nil
          location.poems = nil
        }

        for tag in cdTags {
          tag.poems = nil
        }

        for annal in cdAnnals {
          annal.locations = nil
          annal.poems = nil
        }

        for poem in cdPoems {
          poem.annal = nil
          poem.locations = nil
          poem.tags = nil
        }

        // Update relations

        for jsonEra in jsonEras {
          // Era has empire id
          let cdEra = jsonEra.findRelatedCDInstance(from: cdEras)!
          let cdEmpire = cdEmpires.first { $0.templeName == jsonEra.empire }
          cdEra.empire = cdEmpire
        }

        for jsonAnnal in jsonAnnals {
          // Ana has location list
          let cdAnnal = jsonAnnal.findRelatedCDInstance(from: cdAnnals)!
          let locationIds = Set(jsonAnnal.locations)
          let relatedLocations = cdLocations.filter { locationIds.contains($0.uniqueName) }
          cdAnnal.locations = Set(relatedLocations)
        }

        for jsonPoem in jsonPoems {
          let cdPoem = jsonPoem.findRelatedCDInstance(from: cdPoems)!
          // Poem has tag list
          let tags = Set(jsonPoem.tags)
          let cdTags = cdTags.filter { tags.contains($0.name) }
          cdPoem.tags = Set(cdTags)
          // poem has location list
          let locationIds = Set(jsonPoem.locations)
          let relatedLocations = cdLocations.filter { locationIds.contains($0.uniqueName) }
          cdPoem.locations = Set(relatedLocations)

          // Poem has annal
          let annalID = jsonPoem.age
          let relatedAnnal = cdAnnals.first { $0.age == annalID }
          cdPoem.annal = relatedAnnal
        }
      }
    }
    catch {
      hAssertFailure("fail \(error)")
    }
  }

  private func update<T: JSONDBType>(_ TT: T.Type) throws {
    let localInstances = try TT.getLocalInstances()

    let localInstanceMap = localInstances.reduce(into: [T.ID: T]()) { partialResult, localInstance in
      partialResult[localInstance.id] = localInstance
    }

    dataLog("\(T.Type.self): localInstances \(localInstances.count)")
    hAssertion(localInstances.count == localInstanceMap.count, "\(T.Type.self): Local data should have same id")

    let moc = HCoreDataStack.shared.privateManagedContext

    var currentInstancesInCloud = try {
      let fetchRequest = T.CDType.sortedFetchRequest(with: .alwayTrue)
      let instances = try moc.fetch(fetchRequest)
      return instances
    }()
    dataLog("\(T.Type.self): currentLocationsInCloud \(currentInstancesInCloud.count)")

    var indexesToRemove = [Int]()
    for (index, cdInstance) in currentInstancesInCloud.enumerated() {
      if let local = localInstanceMap[cdInstance.jsonID] {
        local.update(cdInstance)
      }
      else {
        indexesToRemove.append(index)
      }
    }

    moc.performAndWait {
      for index in indexesToRemove.reversed() {
        let cdInstance = currentInstancesInCloud[index]
        cdInstance.deleteInCloud()
        currentInstancesInCloud.remove(at: index)
      }
      dataLog("\(T.Type.self): Remove \(indexesToRemove.count) from cloud")
    }

    if moc.hasChanges {
      let saveSuccess = moc.saveOrRollback()
      dataLog("\(T.Type.self): Save  \(saveSuccess)")
    }

    // Check any new added location

    let cloudLocationMap = currentInstancesInCloud.reduce(into: [T.ID: T.CDType]()) { $0[$1.jsonID] = $1 }

    for localInstance in localInstances {
      if cloudLocationMap[localInstance.id] == nil {
        localInstance.insertCoreData(into: moc)
        dataLog("\(T.Type.self): Add \(localInstance.id) to cloud")
      }
    }
  }

  private func updateLocation() throws {
    let localLocations = try JSONLocation.getLocalInstances()

    let localLocationsMap = localLocations.reduce(into: [String: JSONLocation]()) { partialResult, location in
      partialResult[location.id] = location
    }

    let moc = HCoreDataStack.shared.privateManagedContext

    var currentLocationsInCloud = try {
      let fetchRequest = CDLocation.sortedFetchRequest(with: .alwayTrue)
      let cdLocations = try moc.fetch(fetchRequest)
      return cdLocations
    }()
    dataLog("currentLocationsInCloud \(currentLocationsInCloud.count)")

    var indexesToRemove = [Int]()
    for (index, cdLocation) in currentLocationsInCloud.enumerated() {
      if let local = localLocationsMap[cdLocation.uniqueName] {
        cdLocation.update(from: local)
      }
      else {
        indexesToRemove.append(index)
      }
    }

    moc.performChanges {
      for index in indexesToRemove.reversed() {
        let cdLocation = currentLocationsInCloud[index]
        cdLocation.deleteInCloud()
        currentLocationsInCloud.remove(at: index)
      }
      dataLog("Remove \(indexesToRemove.count) from cloud")
    }

    // Check any new added location

    let cloudLocationMap = currentLocationsInCloud.reduce(into: [String: CDLocation]()) { $0[$1.uniqueName] = $1 }

    for local in localLocations {
      if cloudLocationMap[local.uniqueName] == nil {
        CDLocation.insert(local, into: moc)
        dataLog("Add \(local.uniqueName) to cloud")
      }
    }
  }

  func updateEras() throws {
    let localLocations = try JSONEra.getLocalInstances()

    let localLocationsMap = localLocations.reduce(into: [Int: JSONEra]()) { partialResult, location in
      partialResult[location.id] = location
    }

    let moc = HCoreDataStack.shared.privateManagedContext

    var currentLocationsInCloud = try {
      let fetchRequest = CDEra.sortedFetchRequest(with: .alwayTrue)
      let cdLocations = try moc.fetch(fetchRequest)
      return cdLocations
    }()
    dataLog("currentLocationsInCloud \(currentLocationsInCloud.count)")

    var indexesToRemove = [Int]()
    for (index, cdLocation) in currentLocationsInCloud.enumerated() {
      if let local = localLocationsMap[cdLocation.id] {
        cdLocation.update(from: local)
      }
      else {
        indexesToRemove.append(index)
      }
    }

    moc.performChanges {
      for index in indexesToRemove.reversed() {
        let cdLocation = currentLocationsInCloud[index]
        cdLocation.deleteInCloud()
        currentLocationsInCloud.remove(at: index)
      }
      dataLog("Remove \(indexesToRemove.count) from cloud")
    }

    // Check any new added location

    let cloudLocationMap = currentLocationsInCloud.reduce(into: [Int: CDEra]()) { $0[$1.id] = $1 }

    for local in localLocations {
      if cloudLocationMap[local.id] == nil {
        CDEra.insert(local, into: moc)
        dataLog("Add \(local.id) to cloud")
      }
    }
  }
}
