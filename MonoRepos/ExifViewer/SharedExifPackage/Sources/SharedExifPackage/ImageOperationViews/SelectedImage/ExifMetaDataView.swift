//
//  ExifMetaDataView.swift
//  SharedExifPackage
//
//  Created by tigerguo on 2025/3/8.
//

import HLocation
import SwiftUI

@MainActor
struct ExifMetaDataView: View {
  let imageMetaData: ImageMetaData
  var body: some View {
    VStack {
      BasicInfoView(imageMetaData: imageMetaData)
    }
  }
}

extension ExifMetaDataView {
  @MainActor struct BasicInfoView: View {
    let imageMetaData: ImageMetaData
    var body: some View {
      GroupBox {
        groupView
      } label: {
        Text(ExifString.PhotoDisplay.basicInfoLabel.hDocLocalized())
          .font(.headline)
      }
    }

    @ViewBuilder
    var groupView: some View {
      let location = imageMetaData.location.value?.location.map {
        HLocationConvertor.marsCoordinate(fromGPSCoordinate: $0.coordinate)
      }
      MetadataFieldView(metadataField: imageMetaData.fileName)
      MetadataFieldView(metadataField: imageMetaData.fileSizeInBytes)
      MetadataFieldView(metadataField: imageMetaData.dimension)
      MetadataFieldView(metadataField: imageMetaData.dateTimeOriginal)
      MetadataFieldView(metadataField: imageMetaData.dateTimeDigitized)
      MetadataLocationView(location: location)
    }
  }
}

#Preview { @MainActor in

  NavigationStack {
    ScrollView {
      ExifMetaDataView(imageMetaData: .demo)
    }
  }
}

#Preview("Basic") { @MainActor in

  NavigationStack {
    ScrollView {
      VStack {
        ExifMetaDataView.BasicInfoView(imageMetaData: .demo)
      }
    }
  }
}
