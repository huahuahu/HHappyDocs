//
//  MomentCloudStateManager.swift
//  HDiary
//
//  Created by tigerguo on 2024/12/10.
//

#if os(iOS)

import CloudKit
import HDiaryConstants
import HDiaryModel
import Observation

enum MomentCloudStatus: Sendable, Hashable, Equatable, CaseIterable {
  case synced
  case notSynced
  case unknown
}

@MainActor @Observable
final class MomentCloudStateManager {
  enum Constants {
    static let numberOfLatestItemsToSync = 10
  }

  static let shared = MomentCloudStateManager()

  var shouldSync = true
  private init() {
    Task {
      await startCheckUnSyncedMoment()
    }
  }

  public private(set) var momentCloudStatus: [UUID: MomentCloudStatus] = [:]

  func addMomentToSync(_ moment: Moment) {
    if momentCloudStatus[moment.uuid] == nil {
      momentCloudStatus[moment.uuid] = .notSynced
      Task {
        await syncMoment(moment.uuid)
      }
    }
  }

  private func syncMoment(_ momentUUID: UUID) async {
    #if DEBUG
      guard shouldSync else {
        Log.data.info("No need to sync moment")
        return
      }
    #endif
    let container = CKContainer(identifier: AppConstants.cloudKitContainerIdentifier)
    let database = container.privateCloudDatabase
    let predicate = NSPredicate(format: "CD_uuid == %@", momentUUID.uuidString)
    let query = CKQuery(recordType: Moment.recordType, predicate: predicate)

    do {
      Log.data.info("Checking moment in cloud: \(momentUUID, privacy: .public)")
      let (matchedResults, _) = try await database.records(matching: query, desiredKeys: [Moment.nameFieldInCloud], resultsLimit: 1)
      if matchedResults.contains(where: { matchedResult in
        let (_, result) = matchedResult
        switch result {
        case .success:
          Log.data.info("Moment already synced to cloud: \(momentUUID, privacy: .public)")
          return true
        case .failure(let failure):
          Log.data.error("Failed to sync moment from cloud: \(failure, privacy: .public), moment: \(momentUUID, privacy: .public)")
          return false
        }
      }) {
        momentCloudStatus[momentUUID] = .synced
      }
      else {
        Log.data.info("Moment has not synced to cloud: \(momentUUID, privacy: .public)")
        momentCloudStatus[momentUUID] = .notSynced
      }
    }
    catch {
      Log.data.error("Failed to sync moment from cloud: \(error, privacy: .public), moment: \(momentUUID, privacy: .public)")
    }
  }

  private func startCheckUnSyncedMoment() async {
    #if DEBUG
      guard shouldSync else {
        Log.data.info("No need to sync moment")
        return
      }
    #endif

    Log.data.info("Start check unSynced moment")
    var unSyncedMomentCount = 0
    for (momentUUID, status) in momentCloudStatus {
      if status == .notSynced {
        unSyncedMomentCount += 1
        await syncMoment(momentUUID)
      }
    }
    Log.data.info("Check unSynced moment finished, \(unSyncedMomentCount) unSynced moments")

    do {
      try await Task.sleep(nanoseconds: 30 * NSEC_PER_SEC)
    }
    catch {
      Log.data.error("Failed to sleep: \(error, privacy: .public)")
    }
    await startCheckUnSyncedMoment()
  }
}

#endif
