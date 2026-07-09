//
//  CloudDataEntryModel.swift
//  HDiary
//
//  Created by tigerguo on 2024/9/30.
//

#if os(iOS)

import CloudKit
import HDiaryConstants
import Observation

@MainActor
private final class CloudDataEntryModelStorage {
  let container = CKContainer(identifier: AppConstants.cloudKitContainerIdentifier)
  let database: CKDatabase

  init() {
    database = container.privateCloudDatabase
  }
}

@MainActor @Observable
final class CloudDataEntryModel<T: CloudRecord> {
  enum State {
    case idle
    case loading
    case loaded(modifiedDate: Date?)
    case error(Error)

    var isLoading: Bool {
      switch self {
      case .loading:
        return true
      default:
        return false
      }
    }

    var isIdle: Bool {
      switch self {
      case .idle:
        return true
      default:
        return false
      }
    }

    var isError: Bool {
      switch self {
      case .error:
        return true
      default:
        return false
      }
    }
  }

  private(set) var state = State.idle
  private let storage = CloudDataEntryModelStorage()

  deinit { }

  func refresh() async {
    state = .loading
    Log.data.info("Loading modificationDate for \(T.recordType, privacy: .public)")
    let predicate = NSPredicate(value: true)
    let query = CKQuery(recordType: T.recordType, predicate: predicate)

    // Sort records by modificationDate (descending)
    let sortDescriptor = NSSortDescriptor(key: "modificationDate", ascending: false)
    query.sortDescriptors = [sortDescriptor]

    // Create CKQueryOperation with resultsLimit set to 1
    do {
      let results = try await storage.database.records(matching: query, desiredKeys: [], resultsLimit: 1)
      guard let matchedResult = results.matchResults.first else {
        // No record
        state = .loaded(modifiedDate: nil)
        Log.data.info("No record for \(T.recordType, privacy: .public)")

        return
      }

      let (_, result) = matchedResult
      switch result {
      case .success(let record):
        state = .loaded(modifiedDate: record.modificationDate)
        Log.data.info("Get latest modification data for  \(T.recordType, privacy: .public)")
      case .failure(let failure):
        Log.data.info("record with latest modification data for \(T.recordType, privacy: .public) fails with error  \(failure.localizedDescription)")
        state = .error(failure)
      }
    }
    catch {
      Log.data.error("Failed when query latest for \(T.recordType, privacy: .public) fails with error \(error.localizedDescription)")
      state = .error(error)
    }
  }
}

#endif
