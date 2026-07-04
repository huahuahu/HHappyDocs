// import CloudKit
// import Combine
// import CoreData
// import Foundation
// import SwiftUI
//
// class LocationImageStore: ObservableObject {
//  @Published private var locationID: String?
//  private var commonStore: ICloudCommonStore<LocationImage, LDCDLocationImage>?
//  private var anyCancellables = Set<AnyCancellable>()
//  private var persistSubscribers = Set<AnyCancellable>()
//
//  @Published var state: DataSyncState<[LocationImage]> = .initial
//
//  init() {
//    dataLog("store init")
//    $locationID
//      .compactMap { $0 }
//      .removeDuplicates()
//      .sink { [weak self] newLocationID in
//        dataLog("new locationID \(newLocationID)")
//        self?.onNewLocationID(newLocationID)
//      }
//      .store(in: &persistSubscribers)
//  }
//
//  private func onNewLocationID(_ locationID: String) {
//    anyCancellables.removeAll()
//    state = .initial
//    let sorDescriptor = NSSortDescriptor(key: ICloudLocationImageConstants.DBKey.date, ascending: true)
//    let cdPublisher: CDFetcher<LDCDLocationImage> = {
//      let request = NSFetchRequest<LDCDLocationImage>(entityName: CDConstants.localLocationImageEntityName)
//      request.predicate = NSPredicate(format: "\(ICloudLocationImageConstants.DBKey.locationID) = %@", locationID)
//      request.sortDescriptors = [sorDescriptor]
//      return CDFetcher(request: request, context: HCoreDataStack.shared.localManagedContext)
//    }()
//
//    let iCloudConfig = CommonICloudFetch.Config<LocationImage>.init(
//      recordName: CDConstants.iCloudLocationImageRecordname,
//      predicate: NSPredicate(format: "\(ICloudLocationImageConstants.DBKey.locationID) = %@", locationID),
//      sortDescriptors: [sorDescriptor]
//    ) { record in
//      try CKRecordToLocationImageConverter().locationImageFromCKRecord(record)
//    }
//
//    let config = ICloudCommonStore<LocationImage, LDCDLocationImage>.Config(
//      localToNetConverter: { LocationImage($0) },
//      cdPublisher: cdPublisher,
//      iCloudFetchConfig: iCloudConfig
//    ) { netItems, localItems, moc in
//      CKRecordToLocationImageConverter().mergeLocalNetItems(netItems: netItems, localItems: localItems, moc: moc)
//    }
//
//    commonStore = ICloudCommonStore<LocationImage, LDCDLocationImage>.init(config: config)
////    commonStore?.$state
////      .assign(to: &$state)
//
//    commonStore?.$state.sink(receiveValue: { value in
//      self.state = value.map { comments in
//
//        let ui = comments
//        dataLog("ui upate \(ui)")
//        return ui
//      }
//    })
//    .store(in: &anyCancellables)
//
//    $state.sink { newState in
//      dataLog("\(newState)")
//    }
//    .store(in: &anyCancellables)
//    Task {
//      await commonStore?.refresh()
//    }
//  }
//
//  func refresh() async {
//    await commonStore?.refresh()
//  }
//
//  func updateLocationID(_ locationID: String) {
//    self.locationID = locationID
//  }
// }
