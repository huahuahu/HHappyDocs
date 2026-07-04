//
//  ShareButton.swift
//  SharedExifPackage
//
//  Created by tigerguo on 2025/3/9.
//

import Photos
import SwiftUI

@MainActor
struct ShareButton: View {
  private struct ErrorModel {
    let title: String
    let message: String
  }

  @Environment(\.supportEdit) var supportEdit
  @State private var isShareSheetPresented = false
  let url: URL

  @State private var showPromoteSheet = false

  // Add states for error handling
  @State private var showErrorAlert = false
  @State private var errorModel: ErrorModel = ErrorModel(title: "", message: "")
  @State private var showSuccessAlert = false

  var body: some View {
    Button(action: {
      isShareSheetPresented = true
    }) {
      Label {
        Text(ExifString.Common.share.hDocLocalized())
      } icon: {
        Image(hExifSymbol: .share)
      }
    }
    .buttonStyle(.borderedProminent)
    .confirmationDialog(
      ExifString.Common.share.hDocLocalized(),
      isPresented: $isShareSheetPresented,
      titleVisibility: .hidden
    ) {
      shareRawLink
      shareWithoutRawLinkButton
      saveToAlbumButton
      Button(ExifString.Common.cancel.hDocLocalized(), role: .cancel) {}
    }
    .alert(
      errorModel.title,
      isPresented: $showErrorAlert,
      actions: {},
      message: {
        Text(errorModel.message)
      }
    )
    .alert(
      ExifString.MetaDataEdit.saveSuccessTitle.hDocLocalized(),
      isPresented: $showSuccessAlert,
      actions: {},
      message: {
        Text(ExifString.MetaDataEdit.saveSuccessMessage.hDocLocalized())
      }
    )
    .sheet(isPresented: $showPromoteSheet) {
      NavigationStack {
        PromotionScreen()
      }
    }
  }

  @ViewBuilder
  private var shareRawLink: some View {
    ShareLink(item: url) {
      Text(ExifString.Share.withMetadata.hDocLocalized())
    }
  }

  @ViewBuilder
  private var shareWithoutRawLinkButton: some View {
    Button(action: {
      if supportEdit {
        removeExifAndShare()
      }
      else {
        showPromoteSheet = true
      }
    }) {
      Label {
        Text(ExifString.Share.withoutMetadata.hDocLocalized())
      } icon: {
        Image(hExifSymbol: .promote)
      }
    }
  }

  private func removeExifAndShare() {
    // create target url by adding "no_metadata" at end of original url
    // 1.jpg -> 1_no_metadata.jpg
    let pathExtension = url.pathExtension
    let originalName = url.deletingPathExtension().lastPathComponent
    let newName = "\(originalName)_no_metadata"

    let noMetadataUrl = url.deletingLastPathComponent().appendingPathComponent(newName).appendingPathExtension(pathExtension)
    do {
      try ExifRemovalUtil.removeExif(from: url, outputURL: noMetadataUrl)
      showShareSheet(with: noMetadataUrl)
    }
    catch {
      errorModel = ErrorModel(
        title: ExifString.MetaDataEdit.failedToRemoveExif(error.errorCode),
        message: ExifString.MetaDataEdit.failedToRemoveExif(error.errorCode)
      )
      showErrorAlert = true
    }
  }

  private func showShareSheet(with newURL: URL) {
    // Present UIActivityViewController or use a SwiftUI ShareLink, etc.
    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
       let window = windowScene.windows.first,
       let rootViewController = window.rootViewController {
      let activityVC = UIActivityViewController(
        activityItems: [newURL],
        applicationActivities: nil
      )
      rootViewController.present(activityVC, animated: true)
    }
    else {
      Log.common.error("Failed to get root view controller")
    }
  }

  @ViewBuilder
  private var saveToAlbumButton: some View {
    Button(action: {
      if supportEdit {
        Task {
          await saveToNewAlbum()
        }
      }
      else {
        showPromoteSheet = true
      }
    }) {
      Label {
        Text(ExifString.MetaDataEdit.saveWithoutMetadata.hDocLocalized())
      } icon: {
        Image(hExifSymbol: .saveToAlbum)
      }
    }
  }

  @MainActor
  private func saveToNewAlbum() async {
    let pathExtension = url.pathExtension
    let originalName = url.deletingPathExtension().lastPathComponent
    let newName = "\(originalName)_no_metadata"
    let noMetadataUrl = url.deletingLastPathComponent().appendingPathComponent(newName).appendingPathExtension(pathExtension)

    do {
      try ExifRemovalUtil.removeExif(from: url, outputURL: noMetadataUrl)

      let albumName = ExifString.Common.editedAlbumName.hDocLocalized()
      try await PHUtil.save(imageUrl: noMetadataUrl, toAlbumNamed: albumName)

      Log.common.info("image saved")
      showSuccessAlert = true
    }
    catch let error as ExifRemovalUtil.ExifRemovalError {
      errorModel = ErrorModel(
        title: ExifString.MetaDataEdit.failedToRemoveExif(error.errorCode),
        message: ExifString.MetaDataEdit.failedToRemoveExif(error.errorCode)
      )
      showErrorAlert = true
    }
    catch let error as PHUtil.PHUtilError {
      errorModel = ErrorModel(
        title: error.errorTitle,
        message: error.errorMessage
      )
      showErrorAlert = true
    }
    catch {
      Log.common.error("Failed to save image: \(error)")
      errorModel = ErrorModel(
        title: ExifString.Common.errorTitle.hDocLocalized(),
        message: error.localizedDescription
      )
      showErrorAlert = true
    }
  }
}

#Preview {
  ShareButton(url: URL(string: "https://www.example.com")!)
}
