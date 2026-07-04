//
//  RecordSubscriptionBuyCell.swift
//
//
//  Created by tigerguo on 2024/3/10.
//

#if os(iOS)

  import HDiaryConstants
  import StoreKit
  import SwiftUI

  @MainActor
  public struct RecordSubscriptionBuyCell: View {
    public init() {}

    @Environment(\.recordSubscriptionStatus) private var recordSubscriptionStatus

    @State private var showPurpaseView = false
    public var body: some View {
      Button(action: {
        showPurpaseView = true
      }, label: {
        IAPLabel(status: recordSubscriptionStatus)
      })
      .sheet(isPresented: $showPurpaseView, content: {
        RecordSubscriptionView()
      })
    }
  }

  extension RecordSubscriptionBuyCell {
    fileprivate struct IAPLabel: View {
      init(status: RecordSubscriptionStatus) {
        self.status = status
      }

      let status: RecordSubscriptionStatus
      var body: some View {
        switch status {
        case .notSubscribed:
          Label(
            title: { Text(IAPString.subscibe.hDocLocalized()) },
            icon: { Image(hDiarySymbol: .buy) }
          )

        case .monthly:
          Label(
            title: { Text(IAPString.upgradeToYearlySubscription.hDocLocalized()) },
            icon: { Image(hDiarySymbol: .buy) }
          )

        case .annually:
          Label(
            title: { Text(IAPString.yearlySubscription.hDocLocalized()) },
            icon: { Image(hDiarySymbol: .buy) }
          )
        }
      }
    }
  }

  #Preview {
    Form {
      RecordSubscriptionBuyCell()

      RecordSubscriptionBuyCell.IAPLabel(status: .notSubscribed)
      RecordSubscriptionBuyCell.IAPLabel(status: .monthly(expirationDate: Date().advanced(by: 30 * 24 * 60 * 60)))
      RecordSubscriptionBuyCell.IAPLabel(status: .annually(expirationDate: Date().addingTimeInterval(30 * 24 * 60 * 60)))

      Section {
        RecordSubscriptionBuyCell()

        RecordSubscriptionBuyCell.IAPLabel(status: .notSubscribed)
        RecordSubscriptionBuyCell.IAPLabel(status: .monthly(expirationDate: Date().advanced(by: 30 * 24 * 60 * 60)))
        RecordSubscriptionBuyCell.IAPLabel(status: .annually(expirationDate: Date().advanced(by: 30 * 24 * 60 * 60)))
      }
      .environment(\.locale, .cnMainland)
    }
  }

#endif
