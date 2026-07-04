//
//  CloudDataCell.swift
//  HDoc
//
//  Created by tigerguo on 2024/9/21.
//

import HDocAppConstants
import SwiftUI

extension SettingsView {
  @MainActor
  struct CloudDataCell: View {
    var body: some View {
      NavigationLink(value: HDocNavigationTarget.cloudData(for: .list)) {
        Label {
          Text(HDocString.CloudData.cellLabel)
        } icon: {
          Image(hdocSymbol: .iCloud)
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
