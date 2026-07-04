//
//  DataSyncState.swift
//  Libai
//
//  Created by huahuahu on 2022/3/7.
//

import Foundation

enum DataSyncState<T: Equatable>: Equatable {
  static func == (lhs: DataSyncState<T>, rhs: DataSyncState<T>) -> Bool {
    switch (lhs, rhs) {
    case (.initial, .initial):
      return true
    case let (.loading(localItems: t1), .loading(localItems: t2)):
      return t1 == t2
    case let (.finishWithLocal(items: t1, _), .finishWithLocal(items: t2, netError: _)):
      return t1 == t2
    case let (.finishWithNet(items: t1), .finishWithNet(items: t2)):
      return t1 == t2
    case (.finishWithNetError, .finishWithNetError):
      return true
    default:
      return false
    }
  }

  case initial
  case loading(localItems: T)
  case finishWithLocal(items: T, netError: Error)
  case finishWithNet(items: T)
  case finishWithNetError(netError: Error)

  var debugText: String {
    switch self {
    case .initial:
      return "initial"
    case .loading:
      return "loading, use local "
    case let .finishWithLocal(_, netError):
      return "finish, use local, netError \(netError)"
    case .finishWithNet:
      return "finish use net, success"
    case let .finishWithNetError(netError: netError):
      return "finish use net, error \(netError)"
    }
  }

  var tipsInView: String {
    switch self {
    case .initial:
      return PredefinedString.loading
    case .loading:
      return PredefinedString.loadingShowCache
    case .finishWithLocal:
      return PredefinedString.showCacheWhenNetFail
    case .finishWithNet:
      return PredefinedString.showNetContent
    case .finishWithNetError:
      return PredefinedString.loadFail
    }
  }

  var isInitial: Bool {
    if case .initial = self {
      return true
    }
    return false
  }

  var isLoading: Bool {
    switch self {
    case .initial, .loading:
      return true
    case .finishWithLocal, .finishWithNet, .finishWithNetError:
      return false
    }
  }

  var items: T? {
    switch self {
    case .initial:
      return nil
    case let .loading(localItems):
      return localItems
    case let .finishWithLocal(items, _):
      return items
    case let .finishWithNet(items):
      return items
    case .finishWithNetError:
      return nil
    }
  }

  var netError: Error? {
    if case let .finishWithLocal(_, error) = self {
      return error
    }
    else if case let .finishWithNetError(netError: error) = self {
      return error
    }
    return nil
  }

  var isSyncWithNet: Bool {
    switch self {
    case .initial, .loading:
      return false
    case .finishWithLocal, .finishWithNet, .finishWithNetError:
      return true
    }
  }

  func map<U>(_ transform: (T) throws -> U) -> DataSyncState<U> {
    switch self {
    case .initial:
      return .initial
    case let .loading(localItems):
      do {
        let mapped = try transform(localItems)
        return .loading(localItems: mapped)
      }
      catch {
        return .initial
      }
    case let .finishWithLocal(items, netError):
      do {
        let mapped = try transform(items)
        return .finishWithLocal(items: mapped, netError: netError)
      }
      catch {
        return .finishWithNetError(netError: error)
      }
    case let .finishWithNet(items):
      do {
        let mapped = try transform(items)
        return .finishWithNet(items: mapped)
      }
      catch {
        return .finishWithNetError(netError: error)
      }
    case let .finishWithNetError(netError: error):
      return .finishWithNetError(netError: error)
    }
  }
}
