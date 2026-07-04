//
//  MetadataDescriptionView.swift
//  SharedExifPackage
//
//  Created by tigerguo on 2025/3/17.
//

import SwiftUI

@MainActor
struct MetadataDescriptionView: View {
  let name: String
  let description: String
  @Environment(\.dismiss) private var dismiss
  var body: some View {
    NavigationStack {
      ScrollView {
        VStack {
          Text(description)
            .font(.body)
            .textSelection(.enabled)
        }
      }
      .padding()
      .toolbar(content: {
        toolbarContent
      })
      .navigationTitle(Text(name))
    }
  }

  @ToolbarContentBuilder
  private var toolbarContent: some ToolbarContent {
    ToolbarItem(placement: .confirmationAction) {
      Button {
        dismiss()
      } label: {
        Label {
          Text(ExifString.Common.close.hDocLocalized())
        } icon: {
          Image(hExifSymbol: .remove)
        }
      }
    }
  }
}

#Preview {
  MetadataDescriptionView(name: ExifString.MetaData.dateTimeDigitized.hDocLocalized(), description: ExifString.MetaData.dateTimeDigitizedDescription.hDocLocalized())
}
