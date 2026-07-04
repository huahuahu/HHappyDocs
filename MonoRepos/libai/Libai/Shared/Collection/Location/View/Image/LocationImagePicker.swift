//
//  LocationImagePicker.swift
//  Libai (iOS)
//
//  Created by huahuahu on 2022/4/16.
//

import PhotosUI
import SwiftUI

struct LocationImagePicker: View {
  let locationID: String
  @ScaledMetric private var cornerRadius = 10.0
  @State private var selectedItem: PhotosPickerItem?
  @State private var selectedImageData: Data?

  func saveImage() {
//    guard let selectedImageData = selectedImageData else { return }
//    let locationImage = LocationImage(
//      image: selectedImageData,
//      locationID: locationID,
//      id: UUID().uuidString,
//      userid: ICloudConstants.userID,
//      date: Date.now
//    )
//    Task {
//      do {
//        try await LocationImageSaver().save(locationImage)
//        hLog("image upload finish", scenerio: .ui)
//      }
//      catch {
//        hLog("error \(error)", scenerio: .ui)
//      }
//    }
  }

  var body: some View {
    PhotosPicker(
      selection: $selectedItem,
      matching: .images,
      photoLibrary: .shared()
    ) {
      Label("添加图片", systemImage: SystemImage.add)
        .foregroundColor(.primaryLabel)
        .padding()
        .background(.regularMaterial)
        .cornerRadius(cornerRadius)
    }
    .onChange(of: selectedItem) { _, newItem in
      Task {
        // Retrieve selected asset in the form of Data
        if let data = try? await newItem?.loadTransferable(type: Data.self) {
          selectedImageData = data
          hLog("image", scenerio: .ui)
          saveImage()
        }
      }
    }
  }
}

struct LocationImagePicker_Previews: PreviewProvider {
  static var previews: some View {
    LocationImagePicker(locationID: "test")
  }
}
