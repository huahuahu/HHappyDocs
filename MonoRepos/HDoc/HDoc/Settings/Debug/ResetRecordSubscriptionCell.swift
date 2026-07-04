//
//  ResetRecordSubscriptionCell.swift
//  HDoc
//
//  Created by tigerguo on 2024/1/26.
//

import HDocAppConstants
import SwiftUI

#if DEBUG

  @MainActor
  struct ResetRecordSubscriptionCell: View {
    @Environment(UserPreferences.self) private var userPreferences
    @State private var showAlert = false

    var body: some View {
      Button(action: {
        userPreferences.recordSubscriptionStatusData = nil
        showAlert = true
      }, label: {
        Text(verbatim: "reset local RecordSubscription status")
      })
      .alert(Text(verbatim: "reset success"), isPresented: $showAlert) {
        Button(role: .cancel) {} label: {
          Text(verbatim: "cancel")
        }
      }
    }
  }

  #Preview {
    ResetRecordSubscriptionCell()
  }

#endif
