//
//  MetadataFieldView.swift
//  SharedExifPackage
//
//  Created by tigerguo on 2025/3/8.
//

import SwiftUI

@MainActor
struct MetadataFieldView: View {
  let metadataField: MetadataField

  @State private var showDescription = false
  var body: some View {
    LabeledContent {
      if let displayText = metadataField.displayText {
        Text(displayText)
      }
      else {
        Text(verbatim: "-")
      }
    } label: {
      HStack {
        Text(metadataField.name.hDocLocalized())

        Button {
          showDescription = true
        } label: {
          Label {
            Text(ExifString.MetaDataEdit.infoButtonTitle)
          } icon: {
            Image(hExifSymbol: .info)
          }
          .labelStyle(.iconOnly)
        }
      }
    }
    .sheet(isPresented: $showDescription) {
      MetadataDescriptionView(name: metadataField.name.hDocLocalized(), description: metadataField.description.hDocLocalized())
    }
  }
}

#Preview {
  NavigationStack {
    VStack {
      MetadataFieldView(metadataField: .dateTimeDigitized(ExifDateInfo(date: .now, timeZone: .autoupdatingCurrent)))
    }
    .padding()
  }
}
