//
//  HPasteboardRepresentationView.swift
//  ClipboardInspector
//
//  Created by tigerguo on 2023/3/18.
//

import HUIComponent
import SwiftUI
import UniformTypeIdentifiers

/// Display for a given representation for a pasteboard item
struct HPasteboardRepresentationView: View {
  let representation: HPasteboardItemRepresentation

  @EnvironmentObject var setting: Settings

  @ViewBuilder
  private func utEntry(for utType: UTType) -> some View {
    Section("UTType") {
      HStack {
        NavigationLink(value: utType) {
          Text(utType.identifier)
        }
      }
    }
  }

  var typeView: some View {
    HStack {
      Text(LocalizedString.pasteboardItemRepresentaionType)
      Spacer()
      Text(String(describing: type(of: representation.value)))
    }
  }

  @ViewBuilder
  private var previewCell: some View {
    if HDataType(representation).canPreview() {
      HStack {
        PreviewButton(representation: representation)
      }
    }
    else {
      EmptyView()
    }
  }

  var body: some View {
    List {
      representation.utType.map { utType in
        utEntry(for: utType)
      }
      Section {
        typeView
        HDataTypeView(hDataType: HDataType(representation))
        NavigationLink(value: HDescription(object: representation.value)) {
          Text(LocalizedString.pasteboardItemRepresentaionSystemDescription)
        }

        previewCell
      }
    }
    .navigationTitle(representation.type)
  }
}

struct PastboardRepresentationView_Previews: PreviewProvider {
  static var previews: some View {
    HPasteboardRepresentationView(representation: .plainText)
  }
}
