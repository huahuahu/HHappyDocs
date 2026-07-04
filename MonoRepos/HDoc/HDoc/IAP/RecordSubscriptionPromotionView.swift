//
//  RecordSubscriptionPromotionView.swift
//  HDoc
//
//  Created by tigerguo on 2024/1/17.
//

import Foundation
import HDocAppConstants
import HDocIAP
import HFoundation
import HLocalization
import SwiftUI

@MainActor
public struct RecordSubscriptionPromotionView: View {
  @Environment(UserPreferences.self) private var userPreferences: UserPreferences
  @Environment(\.dismiss) private var dismiss
  @Environment(\.verticalSizeClass) private var verticalSizeClass

  private let skipButtonTapped: () -> Void
  @State private var showIAPView = false

  public init(skipButtonTapped: @escaping () -> Void) {
    self.skipButtonTapped = skipButtonTapped
  }

  public var body: some View {
    let buttonLayout: AnyLayout = verticalSizeClass == .compact ? AnyLayout(HStackLayout(spacing: 30)) : AnyLayout(VStackLayout(spacing: 30))

    NavigationStack {
      ScrollView(.vertical) {
        VStack {
          Text(HDocString.IAP.RecordSubscriptionPromotion.title)
            .font(.largeTitle)
            .bold()
            .multilineTextAlignment(.center)

          Spacer()
          Text(HDocString.IAP.RecordSubscriptionPromotion.description(AppConstants.IAP.freeRecordNumber))
            .font(.body)
            .foregroundStyle(.secondary)
            .padding(.horizontal)

          Spacer()
          buttonLayout {
            purchaseButton
            skipButton
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
      userPreferences.hasPromotedRecordSubscription = true
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
          icon: { Image(hdocSymbol: .xMark).bold() }
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
        title: { Text(HDocString.IAP.RecordSubscriptionPromotion.checkDetail)
        },
        icon: { Image(hdocSymbol: .buy) }
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
      dismiss()
      skipButtonTapped()
    }, label: {
      Label(
        title: { Text(HDocString.IAP.RecordSubscriptionPromotion.skip) },
        icon: { Image(hdocSymbol: .skip).symbolVariant(.circle) }
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
  userPreferences.hasPromotedRecordSubscription = false
  return RecordSubscriptionPromotionView {
    print("skip tapped")
  }
  .environment(userPreferences)
  .environment(\.locale, .cnMainland)
}

#Preview("en") { @MainActor in
  let userPreferences = UserPreferences.shared
  userPreferences.hasPromotedRecordSubscription = false
  return RecordSubscriptionPromotionView {
    print("skip tapped")
  }
  .environment(userPreferences)
  .environment(\.locale, .en)
}
