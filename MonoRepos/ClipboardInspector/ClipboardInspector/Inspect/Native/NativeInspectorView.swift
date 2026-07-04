//
//  NativeInspectorView.swift
//  ClipboardInspector
//
//  Created by tigerguo on 2023/3/18.
//

import HUIComponent
import SwiftUI

/// Display all items in pasteboard, only uti info is displayed
struct NativeInspectorView: View {
  let pasteboardItems: [HPasteboardItem]
  private var listView: some View {
    List {
      ForEach(Array(pasteboardItems.enumerated()), id: \.0) { index, pasteboardItem in
        Section {
          ForEach(pasteboardItem.representations) { representation in
            NavigationLink(value: representation) {
              Text(representation.type)
            }
          }
        } header: {
          Text(LocalizedString.item(for: (index + 1)))
        }
      }
    }
  }

  @ViewBuilder
  private var contentView: some View {
    if HPasteboard.shared.getItems().isEmpty {
      HEmptyView()
        .backgroundStyle(.blue)
    }
    else {
      listView
    }
  }

  var body: some View {
    contentView
    #if os(iOS) || os(visionOS)
    .navigationBarTitleDisplayMode(.inline)
    #endif
  }
}

struct NativeInspectorView_Previews: PreviewProvider {
  static var previews: some View {
    NativeInspectorView(pasteboardItems: [.init(representations: [.plainText])])
  }
}
