import CloudKit
import Foundation

// swiftformat:disable:next redundantSendable
nonisolated struct CloudSyncErrorDetails: Codable, Sendable, Equatable {
  let domain: String
  let code: Int
  let message: String
  let retryAfter: TimeInterval?
  let retryDate: Date?

  static func from(error: any Error, now: Date = Date()) -> Self? {
    let topLevelError = error as NSError
    var visited = Set<ObjectIdentifier>()
    let retryAfter = retryAfter(in: topLevelError, visited: &visited)

    return Self(
      domain: topLevelError.domain,
      code: topLevelError.code,
      message: topLevelError.localizedDescription,
      retryAfter: retryAfter,
      retryDate: retryAfter.map { now.addingTimeInterval($0) }
    )
  }

  private static func retryAfter(
    in error: NSError,
    visited: inout Set<ObjectIdentifier>
  ) -> TimeInterval? {
    guard visited.insert(ObjectIdentifier(error)).inserted else {
      return nil
    }

    if let number = error.userInfo[CKErrorRetryAfterKey] as? NSNumber {
      let seconds = number.doubleValue
      if seconds >= 0 {
        return seconds
      }
    }

    if let underlyingError = nsError(from: error.userInfo[NSUnderlyingErrorKey]),
       let retryAfter = retryAfter(in: underlyingError, visited: &visited) {
      return retryAfter
    }

    for underlyingError in errors(from: error.userInfo[NSMultipleUnderlyingErrorsKey]) {
      if let retryAfter = retryAfter(in: underlyingError, visited: &visited) {
        return retryAfter
      }
    }

    for partialError in partialErrors(from: error.userInfo[CKPartialErrorsByItemIDKey]) {
      if let retryAfter = retryAfter(in: partialError, visited: &visited) {
        return retryAfter
      }
    }

    return nil
  }

  private static func errors(from value: Any?) -> [NSError] {
    guard let value else {
      return []
    }

    if let errors = value as? [NSError] {
      return errors
    }

    guard let values = value as? NSArray else {
      return []
    }
    return values.compactMap(nsError(from:))
  }

  private static func partialErrors(from value: Any?) -> [NSError] {
    guard let dictionary = value as? NSDictionary else {
      return []
    }

    return dictionary.allKeys
      .sorted { String(reflecting: $0) < String(reflecting: $1) }
      .compactMap { key in
        nsError(from: dictionary[key])
      }
  }

  private static func nsError(from value: Any?) -> NSError? {
    if let error = value as? NSError {
      return error
    }
    if let error = value as? any Error {
      return error as NSError
    }
    return nil
  }
}
