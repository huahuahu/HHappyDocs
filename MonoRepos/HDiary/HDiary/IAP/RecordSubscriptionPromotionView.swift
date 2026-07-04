//
//  RecordSubscriptionPromotionView.swift
//  HDoc
//
//  Created by tigerguo on 2024/1/17.
//

import Foundation
import HDiaryConstants
import HDiaryIAP
import HDiaryModel
import HFoundation
import HLocalization
import SwiftData
import SwiftUI

@MainActor
public struct RecordSubscriptionPromotionView: View {
  @Environment(UserPreferences.self) private var userPreferences: UserPreferences
  @Environment(\.dismiss) private var dismiss
  @Environment(\.verticalSizeClass) private var verticalSizeClass
  @Environment(\.recordSubscriptionStatus) private var recordSubscriptionStatus

  private let skipButtonTapped: () -> Void
  @State private var showIAPView = false
  private let currentMomentCount: Int

  public init(currentMomentCount: Int, skipButtonTapped: @escaping () -> Void) {
    self.currentMomentCount = currentMomentCount
    self.skipButtonTapped = skipButtonTapped
  }

  public var body: some View {
    let buttonLayout: AnyLayout = verticalSizeClass == .compact ? AnyLayout(HStackLayout(spacing: 30)) : AnyLayout(VStackLayout(spacing: 30))

    NavigationStack {
      ScrollView(.vertical) {
        VStack {
          Text(DiaryStringKey.IAP.RecordSubscriptionPromotion.title)
            .font(.largeTitle)
            .bold()
            .multilineTextAlignment(.center)

          Spacer()
          Text(DiaryStringKey.IAP.RecordSubscriptionPromotion.description(AppConstants.IAP.freeRecordNumber))
            .font(.body)
            .foregroundStyle(.secondary)
            .padding(.horizontal)

          Spacer()
          buttonLayout {
            purchaseButton
            if case .notSubscribed = recordSubscriptionStatus, currentMomentCount < AppConstants.IAP.freeRecordNumber {
              skipButton
            }
          }
          .fixedSize(
            horizontal: verticalSizeClass != .compact,
            vertical: verticalSizeClass == .compact
          )
          Spacer()
        }
        .padding()
        .containerRelativeFrame(.vertical)
      }
      .scrollTargetLayout()
      .toolbar {
        toolbarContent
      }
    }
    .background(.regularMaterial)
    .task {
      userPreferences.hasShownRecordPromotionView = true
    }
  }

  @ToolbarContentBuilder
  private var toolbarContent: some ToolbarContent {
    ToolbarItemGroup(placement: .primaryAction) {
      Button(action: {
        dismiss()
      }, label: {
        Label(
          title: { Text(HLocalizedString.dismiss) },
          icon: { Image(hDiarySymbol: .xMark).bold() }
        )
      })
    }
  }

  private var purchaseButton: some View {
    Button(action: {
      Log.iap.info("subscribe button tapped in  RecordSubscriptionPromotionView")
      showIAPView = true
    }, label: {
      Label(
        title: { Text(DiaryStringKey.IAP.RecordSubscriptionPromotion.checkDetail)
        },
        icon: { Image(hDiarySymbol: .buy) }
      )
      .font(.title2.bold())
      .padding(.horizontal)
      .frame(maxWidth: .infinity)
    })
    .buttonStyle(.borderedProminent)
    .sheet(isPresented: $showIAPView, onDismiss: {
      dismiss()
    }, content: {
      RecordSubscriptionView()
    })
  }

  private var skipButton: some View {
    Button(action: {
      Log.iap.info("skip tapped in  RecordSubscriptionPromotionView")
      skipButtonTapped()
    }, label: {
      Label(
        title: { Text(DiaryStringKey.IAP.RecordSubscriptionPromotion.skip) },
        icon: { Image(hDiarySymbol: .skip).symbolVariant(.circle) }
      )
      .font(.title2.bold())
      .padding(.horizontal)
      .frame(maxWidth: .infinity)
    })
    .buttonStyle(.borderedProminent)
  }
}

#Preview("cn") { @MainActor in
  let userPreferences = UserPreferences.shared
  userPreferences.hasShownRecordPromotionView = false
  return RecordSubscriptionPromotionView(currentMomentCount: 0) {
    print("skip tapped")
  }
  .environment(userPreferences)
  .environment(\.locale, .cnMainland)
}

#Preview("en") { @MainActor in
  let userPreferences = UserPreferences.shared
  userPreferences.hasShownRecordPromotionView = false
  return RecordSubscriptionPromotionView(currentMomentCount: 0) {
    print("skip tapped")
  }
  .environment(userPreferences)
  .environment(\.locale, .en)
}
