//
//  MetadataEditButton.swift
//  SharedExifPackage
//
//  Created by tigerguo on 2025/3/22.
//

import SwiftUI

@MainActor
struct MetadataEditButton: View {
  // image url
  let url: URL
  @State private var showMetadataEdit = false
  @Environment(\.supportEdit) private var supportEdit
  @State private var showPromotionView = false
  var body: some View {
    Button(action: {
      if supportEdit {
        showMetadataEdit = true
      }
      else {
        showPromotionView = true
      }

    }) {
      Label {
        Text(ExifString.MetaDataEdit.editMetadataButtonTitle.hDocLocalized())
      } icon: {
        Image(hExifSymbol: .edit)
      }
    }
    .buttonStyle(.borderedProminent)
    .tint(supportEdit ? .accentColor : Color(AppConstant.proAppTintColor))
    .sheet(isPresented: $showMetadataEdit) {
      MetaDataEditScreen(url: url)
    }
    .sheet(isPresented: $showPromotionView) {
      PromotionScreen()
    }
  }
}

#Preview { @MainActor in

  NavigationStack {
    ScrollView {
      MetadataEditButton(url: URL(string: "https://www.example.com")!)
    }
  }
}
