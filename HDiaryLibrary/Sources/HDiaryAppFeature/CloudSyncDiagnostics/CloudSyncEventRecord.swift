import Foundation

// swiftformat:disable:next redundantSendable
nonisolated struct CloudSyncEventRecord: Codable, Sendable, Equatable, Identifiable {
  enum Kind: String, Codable, Sendable {
    case setup
    case importData
    case export
  }

  enum State: String, Codable, Sendable {
    case inProgress
    case succeeded
    case failed
  }

  let id: UUID
  let storeIdentifier: String
  let kind: Kind
  let startDate: Date
  let endDate: Date?
  let state: State
  let error: CloudSyncErrorDetails?
}
