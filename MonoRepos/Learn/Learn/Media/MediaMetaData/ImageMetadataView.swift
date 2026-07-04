//
//  ImageMetadataView.swift
//  Learn
//
//  Created by tigerguo on 2024/12/1.
//

import CoreImage
import Foundation
import ImageIO
import SwiftUI

struct ImageMetadataView: View {
  let imageURL: URL

  var body: some View {
    ScrollView {
      VStack {
        if let metadata = getImageMetadata(from: imageURL) {
          // Exif metadata
          if let exif = metadata[kCGImagePropertyExifDictionary as String] as? [String: Any] {
            Section(header: Text("Exif")) {
              ForEach(exif.keys.sorted(), id: \.self) { key in
                if let value = exif[key] {
                  MetadataRow(key: key, value: value)
                }
              }
            }
          }

          // TIFF metadata
          if let tiff = metadata[kCGImagePropertyTIFFDictionary as String] as? [String: Any] {
            Section(header: Text("TIFF")) {
              ForEach(tiff.keys.sorted(), id: \.self) { key in
                if let value = tiff[key] {
                  MetadataRow(key: key, value: value)
                }
              }
            }
          }

          // GPS metadata
          if let gps = metadata[kCGImagePropertyGPSDictionary as String] as? [String: Any] {
            Section(header: Text("GPS")) {
              ForEach(gps.keys.sorted(), id: \.self) { key in
                if let value = gps[key] {
                  MetadataRow(key: key, value: value)
                }
              }
            }
          }

          // Color Information
          if let colorModel = metadata[kCGImagePropertyColorModel as String] as? String {
            Section(header: Text("Color Information")) {
              MetadataRow(key: "Color Model", value: colorModel)
            }
          }
        }
        else {
          Text("No metadata found")
            .padding()
        }
      }
      .padding()
    }
//    .scrollIndicators(fa)

    .navigationTitle("Image Metadata")
    .navigationBarTitleDisplayMode(.inline)
  }

  private func getImageMetadata(from url: URL) -> [String: Any]? {
    guard let ciImage = CIImage(contentsOf: url) else {
      return nil
    }
    return ciImage.properties
  }
}

struct MetadataRow: View {
  let key: String
  let value: Any

  var body: some View {
    LabeledContent {
      Text(formatValue(value))
        .font(.subheadline)
        .foregroundColor(.gray)

    } label: {
      Text(key)
        .font(.headline)
    }
  }

  func formatValue(_ value: Any) -> String {
    if let array = value as? [Any] {
      return array.map { "\($0)" }.joined(separator: ", ")
    }
    else if let stringValue = value as? String {
      return stringValue
    }
    else if let numberValue = value as? NSNumber {
      return "\(numberValue)"
    }
    else {
      return "\(value)"
    }
  }
}

struct MetadataGroup: Identifiable {
  let id = UUID()
  let title: String
  let items: [(key: String, value: String)]
}

#Preview {
  ImageMetadataView(imageURL: URL(string: "https://example.com/image.jpg")!)
}
