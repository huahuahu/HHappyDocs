//
//  ArtWorkModel.swift
//  AppStoreArtWork
//
//  Created by tigerguo on 2025/3/21.
//
import AppKit
import Foundation
import Observation

@Observable
class ArtWorkModel: Identifiable, Codable {
  let id = UUID()
  var title: String = ""
  var subtitle: String = ""
  var image: NSImage?

  init(title: String = "", subtitle: String = "", image: NSImage?) {
    self.title = title
    self.subtitle = subtitle
    self.image = image
  }

  static func getEmptyModel() -> ArtWorkModel {
    ArtWorkModel(image: nil)
  }

  enum CodingKeys: String, CodingKey {
    case title, subtitle, imageData
  }

  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
    subtitle = try container.decodeIfPresent(String.self, forKey: .subtitle) ?? ""

    // 解码图片数据
    if let imageData = try container.decodeIfPresent(Data.self, forKey: .imageData) {
      image = NSImage(data: imageData)
    }
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encodeIfPresent(title, forKey: .title)
    try container.encodeIfPresent(subtitle, forKey: .subtitle)

    // 编码图片数据
    if let image = image,
       let tiffData = image.tiffRepresentation,
       let bitmapImage = NSBitmapImageRep(data: tiffData) {
      let imageData = bitmapImage.representation(using: .png, properties: [:])
      try container.encode(imageData, forKey: .imageData)
    }
  }
}
