//
//  RecordSubscriptionStatus.swift
//
//
//  Created by tigerguo on 2024/3/10.
//

import Foundation
import HDiaryConstants
import StoreKit
import SwiftUI

public enum RecordSubscriptionStatus: Comparable, Hashable, Codable, Sendable {
  case notSubscribed
  case monthly(expirationDate: Date)
  case annually(expirationDate: Date)

  init?(status: Product.SubscriptionInfo.Status, subscriptionDefinition: RecordSubscription) {
    do {
      guard case .verified = status.transaction else {
        Log.iap.error("not verified transaction")
        return nil
      }

      let payloadValue = try status.transaction.payloadValue
      guard let expirationDate = payloadValue.expirationDate else {
        self = .notSubscribed
        return
      }
      guard expirationDate > Date.now else {
        Log.iap.error("expirationDate is \(expirationDate.formatted()), not valid")
        return nil
      }
      if let revokeDate = payloadValue.revocationDate {
        Log.iap.error("revokeDate is \(revokeDate.formatted()), not valid")
        return nil
      }
      if payloadValue.productID == subscriptionDefinition.monthly {
        self = .monthly(expirationDate: expirationDate)
      }
      else if payloadValue.productID == subscriptionDefinition.annually {
        self = .annually(expirationDate: expirationDate)
      }
      else {
        self = .notSubscribed
      }
    }
    catch {
      Log.iap.error("can't get valid paylod value")
      return nil
    }
  }
}

extension RecordSubscriptionStatus: CustomStringConvertible {
  public var description: String {
    switch self {
    case .notSubscribed: "Not Subscribed"
    case .monthly: "monthly"
    case .annually: "Annually"
    }
  }
}

public extension EnvironmentValues {
  enum RecordSubscriptionStatusEnvironmentKey: EnvironmentKey {
    public static let defaultValue: RecordSubscriptionStatus = .notSubscribed
  }

  enum RecordSubscriptionStatusLoadingEnvironmentKey: EnvironmentKey {
    public static let defaultValue = true
  }

  var recordSubscriptionStatus: RecordSubscriptionStatus {
    get { self[RecordSubscriptionStatusEnvironmentKey.self] }
    set { self[RecordSubscriptionStatusEnvironmentKey.self] = newValue }
  }

  var recordSubscriptionStatusIsLoading: Bool {
    get { self[RecordSubscriptionStatusLoadingEnvironmentKey.self] }
    set { self[RecordSubscriptionStatusLoadingEnvironmentKey.self] = newValue }
  }
}
