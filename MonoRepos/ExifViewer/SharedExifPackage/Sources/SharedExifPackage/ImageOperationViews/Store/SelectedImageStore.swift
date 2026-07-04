//
//  SelectedImageStore.swift
//  SharedExifPackage
//
//  Created by tigerguo on 2025/3/8.
//
#if os(iOS)

  import Observation
  import PhotosUI
  import SwiftUI
  import UIKit

  @Observable
  @MainActor final class SelectedImageStore {
    private(set) var imageItems = [ImageItem]()

    init() {
      NotificationCenter.default.addObserver(
        self,
        selector: #selector(appWillTerminate),
        name: UIApplication.willTerminateNotification,
        object: nil
      )
    }

    func getImageItem(for pickerItem: PhotosPickerItem) -> ImageItem? {
      imageItems.first { $0.pickerItem == pickerItem }
    }

    func updatePickerItems(_ pickerItems: [PhotosPickerItem]) {
      var originalItemMap = imageItems.reduce(into: [PhotosPickerItem: ImageItem]()) { partialResult, imageItem in
        partialResult[imageItem.pickerItem] = imageItem
      }
      imageItems.removeAll(keepingCapacity: true)
      for pickerItem in pickerItems {
        if let imageItem = originalItemMap.removeValue(forKey: pickerItem) {
          imageItems.append(imageItem)
        }
        else {
          imageItems.append(ImageItem(pickerItem: pickerItem))
        }
      }

      for imageItemToClear in originalItemMap.values {
        Task {
          await imageItemToClear.clear()
        }
      }
    }

    func removeImageItem(for pickerItem: PhotosPickerItem) {
      guard let imageItem = imageItems.first(where: { $0.pickerItem == pickerItem }) else {
        return
      }
      imageItems.removeAll { $0.pickerItem == pickerItem }
      Task {
        await imageItem.clear()
      }
    }

    @objc private func appWillTerminate() {
      Log.common.info("App will terminate, delete all data before termination")
      for imageItemToClear in imageItems {
        Task {
          await imageItemToClear.clear()
        }
      }
    }

    @objc private func appDidLaunch() {
      Log.common.info("App did launch, clear all data before launch")
      Task {
        do {
          try FileManager.default.removeItem(at: AppConstant.copiedImageFolder)
          Log.common.info("Clear copied image folder succeed")
        }
        catch {
          Log.common.error("Clear copied image folder fails with error: \(error, privacy: .public)")
        }
      }
    }
  }

  @Observable
  @MainActor final class ImageItem: Identifiable {
    let pickerItem: PhotosPickerItem
    var loadState: LoadState = .loading

    enum LoadState: Sendable {
      case loading
      case loadError(String)
      case loaded(fileImage: FileImage, uiImage: UIImage)
    }

    init(pickerItem: PhotosPickerItem) {
      self.pickerItem = pickerItem
      Task {
        await self.loadImage()
      }
    }

    var imageUrl: URL? {
      if case let .loaded(fileImage: fileImage, _) = loadState {
        return fileImage.url
      }
      return nil
    }

    fileprivate nonisolated func clear() async {
      let urlToRemove = await MainActor.run {
        return imageUrl
      }
      guard let urlToRemove = urlToRemove else {
        return
      }
      let imageName = urlToRemove.lastPathComponent
      do {
        try FileManager.default.removeItem(at: urlToRemove.deletingLastPathComponent())
        Log.common.info("Clear copied image \(imageName) succeed")
      }
      catch {
        Log.common.error("Clear copied image \(imageName, privacy: .public) fails with error: \(error, privacy: .public)")
      }
    }

    fileprivate func loadImage() async {
      do {
        guard let fileImage = try await pickerItem.loadTransferable(type: FileImage.self) else {
          Log.common.error("System doesn't find a supported content type")
          loadState = .loadError(ExifString.PhotoDisplay.loadError.hDocLocalized())
          return
        }
        Log.common.debug("Loaded file url: \(fileImage.url)")
        let imageData = try Data(contentsOf: fileImage.url)
        guard let uiImage = UIImage(data: imageData) else {
          Log.common.error("Could not initialize the image from the specified data.")
          loadState = .loadError(ExifString.PhotoDisplay.loadError.hDocLocalized())
          return
        }
        loadState = .loaded(fileImage: fileImage, uiImage: uiImage)
      }
      catch {
        Log.common.error("Error thrown when loading image, error is: \(error)")
        loadState = .loadError(ExifString.PhotoDisplay.loadError.hDocLocalized())
      }
    }
  }
#endif
