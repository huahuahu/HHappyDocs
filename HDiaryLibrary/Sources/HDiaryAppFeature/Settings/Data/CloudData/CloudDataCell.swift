//
//  CloudDataCell.swift
//  HDiary
//
//  Created by tigerguo on 2024/9/29.
//

#if os(iOS)

import HDiaryConstants
import SwiftUI

extension SettingsView {
  @MainActor
  struct CloudDataCell: View {
    var body: some View {
      NavigationLink(value: HDiaryDestination.cloudDataEntry) {
        Label {
          Text(DiaryStringKey.Data.CloudData.cellLabel)
        } icon: {
          Image(hDiarySymbol: .iCloud)
        }
      }
    }
  }
}

#Preview("Cloud Data Cell", body: { @MainActor in
  NavigationStack {
    Form {
      SettingsView.CloudDataCell()
    }
  }
  .previewEnvironment()
})

#endif
