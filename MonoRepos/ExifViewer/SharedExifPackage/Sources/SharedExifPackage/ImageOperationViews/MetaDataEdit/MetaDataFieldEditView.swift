//
//  MetaDataFieldEditView.swift
//  SharedExifPackage
//
//  Created by tigerguo on 2025/3/22.
//

import SwiftUI

@MainActor
struct MetaDataFieldEditView: View {
  let metadataField: MetadataField
  @Binding var editedMetadataField: MetadataField
  init(metadataField: MetadataField, editedMetadataField: Binding<MetadataField>) {
    self.metadataField = metadataField
    self._editedMetadataField = editedMetadataField
  }

  var body: some View {
    Section {
      ContentView(metadataField: metadataField, editedMetadataField: $editedMetadataField)
    } header: {
      headerView
    }
  }

  @ViewBuilder
  private var headerView: some View {
    HeaderView(metadataField: metadataField)
  }
}

extension MetaDataFieldEditView {
  @MainActor
  struct ContentView: View {
    let metadataField: MetadataField
    @State private var showEditView = false
    @Binding var editedMetadataField: MetadataField
    var body: some View {
      Text(editedMetadataField.displayText ?? "")
        .onTapGesture {
          showEditView = true
        }
        .sheet(isPresented: $showEditView) {
          Form {
            switch metadataField.value {
            case .dateInfo(let dateInfo):
              DatePicker(selection: Binding<Date>(
                get: { dateInfo.date },
                set: { newValue in editedMetadataField = MetadataField.dateTimeOriginal(ExifDateInfo(date: newValue, timeZone: dateInfo.timeZone)) }
              )) {
                Text(metadataField.name.hDocLocalized())
              }

            case .string:
              EmptyView()
            case .int:
              EmptyView()
            case .none:
              EmptyView()
            case .location:
              EmptyView()
            }
          }
        }
    }
  }
}

extension MetaDataFieldEditView {
  @MainActor
  struct HeaderView: View {
    let metadataField: MetadataField
    @State private var showDescription = false

    var body: some View {
      HStack {
        Text(metadataField.name)

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
      .sheet(isPresented: $showDescription) {
        MetadataDescriptionView(name: metadataField.name.hDocLocalized(), description: metadataField.description.hDocLocalized())
      }
    }
  }
}

#Preview("header") { @MainActor in
  @Previewable @State var editedMetadataField: MetadataField = MetadataField.dateTimeOriginal(nil)
  Form {
    MetaDataFieldEditView(metadataField: MetadataField.dateTimeOriginal(nil), editedMetadataField: $editedMetadataField)
  }
}
