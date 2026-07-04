//
//  MetaDataEditScreen.swift
//  SharedExifPackage
//
//  Created by tigerguo on 2025/3/22.
//

import Photos
import SwiftUI

@MainActor
struct MetaDataEditScreen: View {
  let url: URL
  @State private var metaData: ImageMetaData?
  @State private var editedMetaData: ImageMetaData?
  @Environment(\.dismiss) private var dismiss

  @State private var showAlert = false
  @State private var alertMessage = ""
  @State private var alertTitle = ""

  var body: some View {
    NavigationStack {
      content
        .onAppear {
          metaData = ImageMetaData(imageUrl: url)
          editedMetaData = metaData
        }
        .navigationTitle(Text(ExifString.MetaDataEdit.editMetadataButtonTitle.hDocLocalized()))
        .toolbar {
          toolBarContent
        }
        .alert(isPresented: $showAlert) {
          Alert(title: Text(alertTitle), message: Text(alertMessage))
        }
    }
    .interactiveDismissDisabled()
  }

  @ToolbarContentBuilder
  private var toolBarContent: some ToolbarContent {
    ToolbarItem(placement: .cancellationAction) {
      Button(action: {
        dismiss()
      }) {
        Label {
          Text(ExifString.Common.cancel.hDocLocalized())
        } icon: {
          Image(hExifSymbol: .remove)
        }
      }
    }
    ToolbarItem(placement: .confirmationAction) {
      Button(action: {
        Task {
          await saveToAlbum()
        }
      }) {
        Label {
          Text(ExifString.Common.save.hDocLocalized())
        } icon: {
          Image(hExifSymbol: .save)
        }
      }
    }
  }

  private func saveToAlbum() async {
    Log.common.info("saving to album")
    do {
      let newImageUrl = try ExifEdit().updateImageMetadata(sourceURL: url, newMetaData: editedMetaData!)

      let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
      guard status.hasPermission else {
        throw PHUtil.PHUtilError.noPermission
      }

      let albumName = ExifString.Common.editedAlbumName.hDocLocalized()
      try await PHUtil.save(imageUrl: newImageUrl, toAlbumNamed: albumName)
      Log.common.info("saved to album \(albumName)")
      alertTitle = ExifString.MetaDataEdit.saveSuccessTitle.hDocLocalized()
      alertMessage = ExifString.MetaDataEdit.saveSuccessMessage.hDocLocalized()

      showAlert = true
    }
    catch let error as PHUtil.PHUtilError {
      Log.common.error("PHUtilError saving to album: \(error)")
      alertTitle = error.errorTitle
      alertMessage = error.errorMessage
      showAlert = true
    }
    catch {
      Log.common.error("Common error saving to album: \(error)")
      alertTitle = ExifString.Common.errorTitle.hDocLocalized()
      alertMessage = error.localizedDescription
      showAlert = true
    }
  }

  @ViewBuilder
  var content: some View {
    if let metaData = metaData, let editedMetaData = editedMetaData {
      Form {
        MetaDataFieldEditView(metadataField: metaData.dateTimeOriginal, editedMetadataField: .init(get: {
          editedMetaData.dateTimeOriginal
        }, set: { newValue in
          editedMetaData.dateTimeOriginal = newValue
        }))
      }
    }
    else {
      Text(verbatim: "No metadata")
    }
  }
}

#Preview { @MainActor in
  NavigationStack {
    MetaDataEditScreen(url: URL(string: "https://www.example.com")!)
  }
}
