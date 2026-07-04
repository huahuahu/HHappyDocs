//
//  RecordSubscriptionModifier.swift
//
//
//  Created by tigerguo on 2024/1/14.
//
#if os(iOS)

  import Foundation
  import HDocAppConstants
  import StoreKit
  import SwiftUI

  @MainActor
  private struct RecordSubscriptionStatusModifier: ViewModifier {
    @Environment(\.recordSubscription) private var recordSubscription

    @Environment(UserPreferences.self) private var userPreferences: UserPreferences
    @State private var state: EntitlementTaskState<RecordSubscriptionStatus> = .loading

    private var isLoading: Bool {
      if case .loading = state { true }
      else { false }
    }

    func body(content: Content) -> some View {
      content
        .subscriptionStatusTask(for: recordSubscription.group) { state in
          Log.iap.info("Checking recordSubscription status")
          let birdBrain = HDocShop.shared
          self.state = await state.map { statuses in
            await birdBrain.status(
              for: statuses,
              recordSubscription: recordSubscription
            )
          }
          // After getting the status, send it to the `DataGeneration`
          // model so the app can generate events with or without early access
          // birds as appropriate.
          switch self.state {
          case .failure(let error):
            Log.iap.error("Failed to check subscription status: \(error)")
            userPreferences.recordSubscriptionStatusData = nil
          case .success(let status):
            Log.iap.info("check subscription stat success, status is \(status)")
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
        .environment(\.recordSubscriptionStatus, state.value ?? .notSubscribed)
        .environment(\.recordSubscriptionStatusIsLoading, isLoading)
        .task {
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
