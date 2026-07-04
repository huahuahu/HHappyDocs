//
//  PHAssetMetaInfoView.swift
//  Learn
//
//  Created by tigerguo on 2023/11/12.
//

import Photos
import SwiftUI

struct PHAssetMetaInfoView: View {
  let identifier: String
  @State private var meta: String = "Loading"
  var body: some View {
    ScrollView {
      TextEditor(text: $meta)
        .containerRelativeFrame(.vertical)

//                .lineLimit(0)
    }
    .onAppear {
      fetchLocationInfo()
    }
  }

  func fetchLocationInfo() {
    // 假设你有一个PHAsset对象，你需要首先将UIImage转换为Data，然后再将Data转换为PHAsset
    if let imageAsset = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil).firstObject {
      Log.common.info("image asset \(imageAsset)")
      if imageAsset.mediaSubtypes.contains(.photoHDR) {
        Log.common.info("image is HDR")
      }
      else {
        Log.common.info("image is not HDR")
      }
      // 获取照片的位置信息
      if let location = imageAsset.location {
        Log.common.info("Latitude: \(location.coordinate.latitude), Longitude: \(location.coordinate.longitude)")
      }
      else {
        Log.common.error("Image does not have location information.")
      }

      getCameraInfo(forAsset: imageAsset)
    }
    else {
      Task { @MainActor in
        self.meta = "Can't find identifider"
      }

      Log.common.error("Can't find identifider")
    }
  }

  func getCameraInfo(forAsset asset: PHAsset) {
    let options = PHVideoRequestOptions()
    options.version = .original

    asset.metadata { metaString in
      Log.common.info("meata \(metaString ?? "")")
      Task { @MainActor in
        if let metaString {
          self.meta = metaString
        }
        else {
          self.meta = "can't find meta"
        }
      }
    }
  }
}

extension PHAsset {
  func metadata(_ completion: @escaping (String?) -> Void) {
    let options = PHContentEditingInputRequestOptions()
    options.isNetworkAccessAllowed = true

    requestContentEditingInput(with: options) { input, info in
      for (key, value) in info {
        print("key: \(key) value \(value)")
      }

      guard let url = input?.fullSizeImageURL,
            let image = CIImage(contentsOf: url)
      else {
        completion(nil)
        return
      }
      let properties = image.properties
      print("\(properties)")
      let tiffDict = properties["{TIFF}"] as? [String: Any]
      _ = tiffDict?["Make"] as? String ?? ""
      completion("\(properties)")
    }
  }
}

#Preview {
  PHAssetMetaInfoView(identifier: "111")
}
