//
//  ExportDataCell.swift
//  HDiary
//
//  Created by tigerguo on 2024/4/9.
//

#if os(iOS)

import Foundation
import HDiaryConstants
import HDiaryModel
import HUIComponent
import SwiftUI

extension SettingsView {
  @MainActor
  struct ExportDataCell: View {
    @Environment(\.modelContext) private var modelContext
    var body: some View {
      ShareLink(
        item: RawDataCollection(modelContext: modelContext),
        subject: Text(DiaryStringKey.Data.Export.subject),
        message: Text(DiaryStringKey.Data.Export.message(AppConstants.appName)),
        preview: SharePreview(Text(DiaryStringKey.Data.Export.subject)),
        label: {
          Label(
            title: { Text(DiaryStringKey.Data.Export.shareLinkLabel) },
            icon: { Image(hDiarySymbol: .exportDoc) }
          )
        }
      )
    }
  }
}

#if DEBUG
  #Preview("en") { @MainActor in
    NavigationStack {
      Form {
        SettingsView.ExportDataCell()
      }
      .previewEnvironment()
    }
    .environment(\.locale, .en)
  }

  #Preview("cn") { @MainActor in
    NavigationStack {
      Form {
        SettingsView.ExportDataCell()
      }
      .previewEnvironment()
    }
    .environment(\.locale, .cnMainland)
  }

#endif

#endif
