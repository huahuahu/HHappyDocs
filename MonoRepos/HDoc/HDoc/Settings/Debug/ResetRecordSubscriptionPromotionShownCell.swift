//
//  ResetRecordSubscriptionPromotionShownCell.swift
//  HDoc
//
//  Created by tigerguo on 2024/1/18.
//

import HDocAppConstants
import SwiftUI

#if DEBUG
  @MainActor
  struct ResetRecordSubscriptionPromotionShownCell: View {
    @Environment(UserPreferences.self) private var userPreferences
    @State private var showAlert = false
    var body: some View {
      Button(action: {
        userPreferences.hasPromotedRecordSubscription = false
        showAlert = true
      }, label: {
        Text(verbatim: "reset RecordSubscription Promotion Shown")
      })
      .alert(Text(verbatim: "reset success"), isPresented: $showAlert) {
        Button(role: .cancel) {} label: {
          Text(verbatim: "cancel")
        }
      }
    }
  }

  // #Preview {
//    ResetRecordSubscriptionPromotionShownView()
  // }

#endif
