//
//  RawDataExportCell.swift
//  HDoc
//
//  Created by tigerguo on 2024/1/12.
//

import HDocAppConstants
import SwiftData
import SwiftUI

@MainActor
struct RawDataExportCell: View {
  @Environment(\.modelContext) private var modelContex
  var body: some View {
    ShareLink(
      item: RawDataCollection(modelContext: modelContex),
      subject: Text(HDocString.Export.Total.subject),
      message: Text(HDocString.Export.Total.message(AppConstants.appName)),
      preview: SharePreview(Text(HDocString.Export.Total.subject)),
      label: {
        Label(
          title: { Text(HDocString.Export.Total.shareLinkLabel) },
          icon: { Image(hdocSymbol: .exportDoc) }
        )
      }
    )
  }
}

#if DEBUG
  #Preview("en") { @MainActor in
    NavigationStack {
      Form {
        RawDataExportCell()
      }
      .previewEnvironment()
    }
  }

  #Preview("cn") { @MainActor in
    NavigationStack {
      Form {
        RawDataExportCell()
      }
      .previewEnvironment()
    }
    .environment(\.locale, .cnMainland)
  }

#endif
