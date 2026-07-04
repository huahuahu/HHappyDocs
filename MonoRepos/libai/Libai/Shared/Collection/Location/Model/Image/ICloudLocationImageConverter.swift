////
////  LocationCommentConstants.swift
////  Libai (iOS)
////
////  Created by huahuahu on 2022/4/10.
////
//
// import CloudKit
// import CoreData
// import Foundation
//
// struct ICloudLocationImageConstants {
//  enum DBKey {
//    static let locationID = "locationID"
//    static let id = "id"
//    static let image = "image"
//    static let userid = "userID"
//    static let date = "date"
//  }
//
//  enum ConvertError: Error {
//    case missProperty
//    case noLocationUniqueName
//  }
// }
//
// struct CKRecordToLocationImageConverter {
//  func locationImageFromCKRecord(_ record: CKRecord) throws -> LocationImage {
//    guard let uniqueName = record[ICloudLocationImageConstants.DBKey.locationID] as? String else {
//      hAssertFailure("no uniqueName")
//      throw ICloudLocationImageConstants.ConvertError.noLocationUniqueName
//    }
//    guard let id = record[ICloudLocationImageConstants.DBKey.id] as? String,
//          let image = record[ICloudLocationImageConstants.DBKey.image] as? CKAsset,
//          let imageUrl = image.fileURL,
//          let imageData = try? Data(contentsOf: imageUrl),
//          let userID = record[ICloudLocationImageConstants.DBKey.userid] as? String,
//          let date = record[ICloudLocationImageConstants.DBKey.date] as Date?
//    else {
//      hAssertFailure("convert Location image fail for \(uniqueName) some property missing")
//      throw ICloudLocationImageConstants.ConvertError.missProperty
//    }
//
//    let locationImage = LocationImage(
//      image: imageData,
//      locationID: uniqueName,
//      id: id,
//      userid: userID,
//      date: date
//    )
//    return locationImage
//  }
//
//  func mergeLocalNetItems(netItems: [LocationImage], localItems: [LDCDLocationImage], moc: NSManagedObjectContext) {
//    var netItems = netItems
//    var localItemsMap: [String: LDCDLocationImage] = localItems.reduce(into: [:]) { $0[$1.id] = $1 }
//
//    var processedNetItemIds: [Int] = []
//    // Find all items that both in net and local
//    netItems.enumerated().forEach { index, netItem in
//      if let localItem = localItemsMap[netItem.id] {
//        localItem.update(from: netItem)
//        localItemsMap[netItem.id] = nil
//        processedNetItemIds.append(index)
//      }
//    }
//
//    // Remove all items from net that already in local
//    processedNetItemIds.reversed().forEach { index in
//      netItems.remove(at: index)
//    }
//    dataLog("find \(processedNetItemIds.count) that both in local and net")
//
//    // Create new items in Core Data for that not in local
//    netItems.forEach { locationImage in
//      let ldcdLocationImage = LDCDLocationImage(context: moc)
//      ldcdLocationImage.update(from: locationImage)
//    }
//
//    dataLog("find \(netItems.count) that new from net")
//
//    // Delete items that no longer from net
//    localItemsMap.values.forEach { ldcdLocation in
//      moc.delete(ldcdLocation)
//    }
//    dataLog("delete \(localItemsMap.count) that no longer in  net")
//
//    do {
//      try HCoreDataStack.shared.saveLocalIfNeed()
//    } catch {
//      // TODO: handle the error
//      dataLog("update db err \(error)")
//    }
//  }
// }
//
// extension LDCDLocationImage {
//  func update(from locationimage: LocationImage) {
//    image = locationimage.image
//    userid = locationimage.userid
//    locationID = locationimage.locationID
//    id = locationimage.id
//    date = locationimage.date
//  }
// }
