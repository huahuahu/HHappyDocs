//
//  RecordSubscriptionModifier.swift
//
//
//  Created by tigerguo on 2024/3/10.
//

#if os(iOS)

  import Foundation
  import HDiaryConstants
  import StoreKit
  import SwiftUI

  @MainActor
  private struct RecordSubscriptionStatusModifier: ViewModifier {
    @Environment(\.recordSubscription) private var recordSubscription

    @Environment(UserPreferences.self) private var userPreferences: UserPreferences
    @State private var state: EntitlementTaskState<RecordSubscriptionStatus> = .loading

    private let appDistribution = AppDistribution.current

    private var subscriptionStatus: RecordSubscriptionStatus {
      state.value ?? .notSubscribed
    }

    private var recordFeatureAccessAllowed: Bool {
      RecordFeatureAccessPolicy.allowsAccess(
        for: subscriptionStatus,
        distribution: appDistribution
      )
    }

    private var isLoading: Bool {
      if case .loading = state { true }
      else { false }
    }

    func body(content: Content) -> some View {
      content
        .subscriptionStatusTask(for: recordSubscription.group) { state in
          Log.iap.info("Checking recordSubscription status")
          let birdBrain = HDiaryShop.shared
          switch state {
          case .success(let statuses):
            let status = await birdBrain.status(
              for: statuses,
              recordSubscription: recordSubscription
            )
            self.state = .success(status)
          case .failure(let error):
            self.state = .failure(error)
          case .loading:
            self.state = .loading
          @unknown default:
            self.state = .loading
          }
          // After getting the status, send it to the `DataGeneration`
          // model so the app can generate events with or without early access
          // birds as appropriate.
          switch self.state {
          case .failure(let error):
            Log.iap.error("Failed to check subscription status: \(error, privacy: .public)")
            userPreferences.recordSubscriptionStatusData = nil
          case .success(let status):
            Log.iap.info("check subscription stat success, status is \(status, privacy: .public)")
            do {
              let data = try JSONEncoder().encode(status)
              userPreferences.recordSubscriptionStatusData = data
              Log.iap.info("save recordSubscriptionStatus to disk")
            }
            catch {
              Log.iap.error("when saving recordSubscriptionStatus to disk, failed")
            }
          case .loading: break
          @unknown default: break
          }
          Log.iap.info("Finished checking subscription status")
        }
        .environment(\.recordSubscriptionStatus, subscriptionStatus)
        .environment(\.recordFeatureAccessAllowed, recordFeatureAccessAllowed)
        .environment(\.recordSubscriptionStatusIsLoading, isLoading)
        .task {
          Log.iap.info(
            "App distribution: \(String(describing: appDistribution), privacy: .public)"
          )
          readDataFromDisk()
        }
    }

    private func readDataFromDisk() {
      if let recordSubscriptionStatusData = userPreferences.recordSubscriptionStatusData {
        do {
          let recordSubscriptionStatus = try JSONDecoder().decode(RecordSubscriptionStatus.self, from: recordSubscriptionStatusData)
          switch recordSubscriptionStatus {
          case let .annually(expirationDate: date), let .monthly(expirationDate: date):
            if date < Date.now {
              Log.iap.info("recordSubscriptionStatus from disk has expired, expired date is \(date.formatted())")
              return
            }
            else {
              state = .success(recordSubscriptionStatus)
              Log.iap.info("read recordSubscriptionStatus data from disk")
            }
          case .notSubscribed:
            Log.iap.info("recordSubscriptionStatus from disk is unsubscribed")
            return
          }
        }
        catch {
          Log.iap.error("Can't get recordSubscriptionStatus from disk, error is \(error)")
        }
      }
      else {
        Log.iap.info("No recordSubscriptionStatus data from disk")
      }
    }
  }

  extension View {
    @MainActor
    public func recordSubscriptionPassStatusTask() -> some View {
      modifier(RecordSubscriptionStatusModifier())
    }
  }
#endif
