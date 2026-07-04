//
//  HCoreDataStack.swift
//  Libai (iOS)
//
//  Created by huahuahu on 2022/3/4.
//

import CloudKit
import CoreData
import Foundation
import LibaiAppConstants

final class HCoreDataStack {
  enum Constants {
    static let transactionAuthor = "libai-app"
  }

  static let shared = HCoreDataStack()
  private init() {}

  let privateContainer: NSPersistentCloudKitContainer = {
    let container = NSPersistentCloudKitContainer(name: "Libai")

    let url = AppConstants.containerURL.appendingPathComponent("LibaiCoreData", isDirectory: true)

    let publicLocation = url.appending(component: "public.sqlite")
    let publicOneDescription = NSPersistentStoreDescription(url: publicLocation)
    publicOneDescription.configuration = "publicCloud"

    // Set the container options on the cloud store
    publicOneDescription.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
      containerIdentifier: AppConstants.cloudKitContainerIdentifier)
    publicOneDescription.cloudKitContainerOptions?.databaseScope = .public
    publicOneDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
    publicOneDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

    container.persistentStoreDescriptions = [publicOneDescription]

    container.loadPersistentStores { loadedStoreDescription, error in
      if let error = error {
        hAssertFailure("core data load error: \(error)")
      }
      print("huahuahu \(loadedStoreDescription)")
    }

    container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    container.viewContext.transactionAuthor = Constants.transactionAuthor

    // Pin the viewContext to the current generation token, and set it to keep itself up to date with local changes.
    container.viewContext.automaticallyMergesChangesFromParent = true
    do {
      try container.viewContext.setQueryGenerationFrom(.current)
    }
    catch {
      fatalError("###\(#function): Failed to pin viewContext to the current generation:\(error)")
    }

    #if DEBUG
//  do {
//    // Use the container to initialize the development schema.
//      try container.initializeCloudKitSchema(options: [.printSchema])
//  } catch {
//    // Handle any errors.
//      dataLog("initializeCloudKitSchema fail \(error)")
//  }
    #endif
    return container
  }()

  var privateManagedContext: NSManagedObjectContext {
    privateContainer.viewContext
  }
}
