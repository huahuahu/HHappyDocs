//
//  PHUtil.swift
//  SharedExifPackage
//
//  Created by tigerguo on 2025/3/15.
//

import Photos

enum PHUtil {
  static func save(imageUrl: URL, toAlbumNamed albumName: String) async throws {
    let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
    guard status.hasPermission else {
      throw Self.PHUtilError.noPermission
    }

    let album = Self.getAlbum(named: albumName)
    // 如果相册不存在则创建
    if let album {
      try await Self.save(imageUrl: imageUrl, to: album)
    }
    else {
      let newAlbum = try await Self.createAlbum(named: albumName)
      if let newAlbum {
        try await Self.save(imageUrl: imageUrl, to: newAlbum)
      }
      else {
        Log.common.error("Failed to create album")
        throw PHUtilError.createAlbumFailed
      }
    }
  }

  static func save(imageUrl: URL, to album: PHAssetCollection) async throws {
    Log.common.info("save image to album \(album.localizedTitle ?? "")")
    let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
    guard status.hasPermission else {
      Log.common.error("no permission to save image to album")
      throw PHUtilError.noPermission
    }

    try await PHPhotoLibrary.shared().performChanges {
      let request = PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: imageUrl)
      guard let assetPlaceholder = request?.placeholderForCreatedAsset else {
        Log.common.error("no placeholder for created asset")
        return
      }

      let albumChangeRequest = PHAssetCollectionChangeRequest(for: album)
      albumChangeRequest?.addAssets([assetPlaceholder] as NSArray)
    }
    Log.common.info("save image to album \(album.localizedTitle ?? "") done")
  }

  // 创建相册
  static func createAlbum(named name: String) async throws -> PHAssetCollection? {
    Log.common.info("create album \(name)")
    let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
    guard status == .authorized || status == .limited else {
      Log.common.error("no permission to create album")
      throw PHUtilError.noPermission
    }
    try await PHPhotoLibrary.shared().performChanges {
      PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: name)
    }
    Log.common.info("create album \(name) done")
    return getAlbum(named: name)
  }

  // 查找相册
  static func getAlbum(named name: String) -> PHAssetCollection? {
    let collections = PHAssetCollection.fetchAssetCollections(
      with: .album,
      subtype: .any,
      options: nil
    )
    Log.common.info("get album \(name)")

    for i in 0 ..< collections.count {
      let collection = collections.object(at: i)
      if collection.localizedTitle == name {
        Log.common.info("get album \(name) done")
        return collection
      }
    }
    Log.common.info("no album \(name)")
    return nil
  }

  enum PHUtilError: Error {
    case noPermission
    case createAlbumFailed

    var errorTitle: String {
      switch self {
      case .noPermission:
        return ExifString.MetaDataEdit.noPhotoPermissionTitle.hDocLocalized()
      case .createAlbumFailed:
        return ExifString.MetaDataEdit.createAlbumFailedTitle.hDocLocalized()
      }
    }

    var errorMessage: String {
      switch self {
      case .noPermission:
        return ExifString.MetaDataEdit.noPhotoPermissionMessage.hDocLocalized()
      case .createAlbumFailed:
        return ExifString.MetaDataEdit.createAlbumFailedMessage.hDocLocalized()
      }
    }
  }
}

extension PHAuthorizationStatus {
  var hasPermission: Bool {
    self == .authorized || self == .limited
  }
}
