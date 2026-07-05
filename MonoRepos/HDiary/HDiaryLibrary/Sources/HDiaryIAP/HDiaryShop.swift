//
//  HDiaryShop.swift
//
//
//  Created by tigerguo on 2024/3/10.
//

import Foundation
import HDiaryConstants
import StoreKit

actor HDiaryShop {
  static let shared = HDiaryShop()
  private init() {
    Task.detached {
      await self.handleUnfinishedTransactions()
    }
  }

  private func handleUnfinishedTransactions() async {
    for await unfinishedTransaction in Transaction.unfinished {
      do {
        try await unfinishedTransaction.payloadValue.finish()
        Log.iap.info("finish transaction \(unfinishedTransaction.jwsRepresentation) success")
      }
      catch {
        Log.iap.info("finish transaction \(unfinishedTransaction.jwsRepresentation) with error \(error, privacy: .public)")
      }
    }
  }

  func status(for statuses: [Product.SubscriptionInfo.Status], recordSubscription: RecordSubscription) -> RecordSubscriptionStatus {
    for status in statuses {
      do {
        let payloadValue = try status.transaction.payloadValue
        Log.iap.info("expirationDate for productID \(payloadValue.productID, privacy: .public) is \(payloadValue.expirationDate?.formatted() ?? "nil", privacy: .public), revoke date is \(payloadValue.revocationDate?.formatted() ?? "nil", privacy: .public)")
        switch status.transaction {
        case .verified:
          Log.iap.info("productID \(payloadValue.productID, privacy: .public) is verified")
        case let .unverified(_, error):
          Log.iap.error("productID \(payloadValue.productID, privacy: .public) unverified \(error)")
        }
      }
      catch {
        Log.iap.error("Get iap status error \(error, privacy: .public)")
      }
    }
    let effectiveStatus = statuses.max { lhs, rhs in
      let lhsStatus = RecordSubscriptionStatus(status: lhs, subscriptionDefinition: recordSubscription) ?? .notSubscribed
      let rhsStatus = RecordSubscriptionStatus(status: rhs, subscriptionDefinition: recordSubscription) ?? .notSubscribed
      return lhsStatus < rhsStatus
    }
    guard let effectiveStatus else {
      return .notSubscribed
    }

    return RecordSubscriptionStatus(status: effectiveStatus, subscriptionDefinition: recordSubscription) ?? .notSubscribed
  }
}
