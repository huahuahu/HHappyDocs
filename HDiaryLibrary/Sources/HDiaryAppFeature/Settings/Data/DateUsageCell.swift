//
//  DateUsageCell.swift
//  HDiary
//
//  Created by tigerguo on 2024/5/25.
//

#if os(iOS)

import HDiaryConstants
import SwiftUI

extension SettingsView {
  @MainActor
  struct DateUsageCell: View {
    var body: some View {
      NavigationLink(value: HDiaryDestination.storageUsage) {
        Label(
          title: { Text(DiaryStringKey.Data.StorageUsage.storageUsage) },
          icon: { Image(hDiarySymbol: .pieChart).symbolVariant(.circle) }
        )
      }
    }
  }
}

#Preview { @MainActor in
  NavigationStack(root: {
    Form {
      SettingsView.DateUsageCell()
    }
  })
}

#endif
