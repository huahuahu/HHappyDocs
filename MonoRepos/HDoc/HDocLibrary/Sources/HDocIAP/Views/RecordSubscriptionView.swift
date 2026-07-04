//
//  RecordSubscriptionView.swift
//
//
//  Created by tigerguo on 2024/1/14.
//

#if os(iOS)
  import StoreKit
  import SwiftUI

  @MainActor
  public struct RecordSubscriptionView: View {
    @Environment(\.recordSubscription.group) private var groupID
    @Environment(\.recordSubscriptionStatus) private var recordSubscriptionStatus

    public init() {}
    private var showUpgrade: Bool {
      if case .monthly = recordSubscriptionStatus {
        return true
      }
      return false
    }

    public var body: some View {
      SubscriptionStoreView(
        groupID: groupID,
        visibleRelationships: showUpgrade ? .upgrade : .all
      ) {
        headView
      }
      .storeButton(.visible, for: .redeemCode)
      .subscriptionStoreButtonLabel(.multiline.displayName)
    }

    private var headView: some View {
      VStack(spacing: 30) {
        Text(IAPString.subscriptionViewTitle.hDocLocalized())
          .font(.largeTitle.bold())
          .padding()
          .foregroundStyle(.bar)
      }
      .background {
        Capsule()
          .fill(.purple.opacity(0.5))
          .blur(radius: 60)
      }
      .multilineTextAlignment(.center)
      .foregroundStyle(.white)
      .containerBackground(for: .subscriptionStoreHeader) {
        LinearGradient(
          colors: [
            .accentColor.opacity(0.5),
            .accentColor,
            .accentColor.opacity(0.5),
          ],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      }
    }
  }

  #Preview("non subscription") { @MainActor in
    Text(verbatim: "test")
      .sheet(isPresented: .constant(true), content: {
        RecordSubscriptionView()
          .tint(.purple)
      })
      .tint(.purple)
  }
#endif
