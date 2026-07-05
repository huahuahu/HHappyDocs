//
//  CloudDataModel.swift
//  HDiary
//
//  Created by tigerguo on 2024/9/30.
//

import CloudKit
import HDiaryConstants
import HDiaryModel

@MainActor @Observable
final class CloudDataModel<T: CloudRecord> {
  // MARK: - VM State

  enum RecordResult: Identifiable {
    case loaded(record: CKRecord, name: String)
    case failure(_ error: Error, uuid: UUID = UUID())

    var id: String {
      switch self {
      case .loaded(let record, _):
        record.recordID.recordName
      case .failure(_, let uuid):
        uuid.uuidString
      }
    }
  }

  enum State {
    case idle
    case loading
    case loaded([RecordResult], cursor: CKQueryOperation.Cursor?, continueLoadError: Error?)
    case continueLoading(previousResult: [RecordResult])
    case error(Error)

    var isLoading: Bool {
      switch self {
      case .loading, .continueLoading:
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
  private let fetchBatchSize = 5

  private let container = CKContainer(identifier: AppConstants.cloudKitContainerIdentifier)
  private let database: CKDatabase

  init() {
    database = container.privateCloudDatabase
  }

  func refresh() async {
    state = .loading
    Log.data.info("Loading items for \(T.recordType, privacy: .public)")
    let predicate = NSPredicate(value: true)
    let query = CKQuery(recordType: T.recordType, predicate: predicate)

    // Sort records by modificationDate (descending)
    let sortDescriptor = NSSortDescriptor(key: "modificationDate", ascending: false)
    query.sortDescriptors = [sortDescriptor]

    do {
      let (matchedResults, queryCursor) = try await database.records(matching: query, desiredKeys: [T.nameFieldInCloud], resultsLimit: fetchBatchSize)

      let recordResults: [RecordResult] = matchedResults.map { matchedResult in
        let (_, result) = matchedResult
        switch result {
        case .success(let record):
          Log.data.debug("Success got one \(T.recordType, privacy: .public)  record")
          let name = record[T.nameFieldInCloud] as? String
          return .loaded(record: record, name: name ?? record.recordID.recordName)
        case .failure(let err):
          Log.data.error("failed when query one item for \(T.recordType, privacy: .public), error is \(err.localizedDescription)")
          return .failure(err)
        }
      }

      state = .loaded(recordResults, cursor: queryCursor, continueLoadError: nil)
    }
    catch {
      Log.data.error("failed when query latest for \(T.recordType, privacy: .public), error is \(error.localizedDescription)")
      state = .error(error)
    }
  }

  func continueFetch() async {
    guard case .loaded(var currentResult, let currentCursor, _) = state else {
      Log.data.error("Invalid operation when continue fetching when state is not loaded")
      return
    }
    guard let currentCursor else {
      Log.data.error("Invalid operation when continue fetching current cursor is nil")

      return
    }

    state = .continueLoading(previousResult: currentResult)

    Log.data.info("continueFetch  for \(T.recordType, privacy: .public)")
    do {
      let (matchedResults, queryCursor) = try await database.records(continuingMatchFrom: currentCursor, resultsLimit: fetchBatchSize)

      let recordResults: [RecordResult] = matchedResults.map { matchedResult in
        let (_, result) = matchedResult
        switch result {
        case .success(let record):
          Log.data.debug("Success got one \(T.recordType, privacy: .public)  record")

          let name = record[T.nameFieldInCloud] as? String
          return .loaded(record: record, name: name ?? record.recordID.recordName)
        case .failure(let err):
          Log.data.error("failed when query one item for \(T.recordType, privacy: .public), error is \(err.localizedDescription)")
          return .failure(err)
        }
      }

      currentResult.append(contentsOf: recordResults)
      state = .loaded(currentResult, cursor: queryCursor, continueLoadError: nil)
    }
    catch {
      state = .loaded(currentResult, cursor: currentCursor, continueLoadError: error)
    }
  }
}
