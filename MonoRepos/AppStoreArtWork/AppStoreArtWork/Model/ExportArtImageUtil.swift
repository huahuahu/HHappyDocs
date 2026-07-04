//
//  ExportArtImageUtil.swift
//  AppStoreArtWork
//
//  Created by tigerguo on 2025/3/21.
//
import AppKit
import Foundation
import SwiftUI

@MainActor
enum ExportArtImageUtil {
  static func export(store: Store) async throws {
    Log.data.info("Starting batch export...")

    // 创建临时目录
    let tempDir = FileManager.default.temporaryDirectory
      .appendingPathComponent("ArtWorkExport-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

    // 按target组织图片
    for (target, models) in store.models {
      if models.isEmpty {
        continue
      }

      let targetDir = tempDir.appendingPathComponent(target.title)
      try FileManager.default.createDirectory(at: targetDir, withIntermediateDirectories: true)
      for model in models {
        guard let image = Self.getRenderResult(for: target, model: model),
              let pngData = image.pngData else {
          Log.data.error("Failed to generate image for model: \(model.id), title: \(model.title)")
          continue
        }

        let fileName = "\(model.id.uuidString).png"
        try pngData.write(to: targetDir.appendingPathComponent(fileName))
      }
    }

    let savePanel = NSSavePanel()
    savePanel.nameFieldStringValue = "ArtWorks"
    savePanel.allowedContentTypes = [.folder]

    let response = await savePanel.begin()
    if response != .OK {
      Log.data.info("User didn't select ok when exporting images")
      return
    }
    guard let saveUrl = savePanel.url else {
      Log.data.error("No url from save panel")
      return
    }
    try FileManager.default.moveItem(at: tempDir, to: saveUrl)

    // 清理临时文件
    try FileManager.default.removeItem(at: tempDir)
  }

  // 压缩工具方法

  static func getRenderResult(for target: Target, model: ArtWorkModel) -> NSImage? {
    let renderer = ImageRenderer(content: ArtWorkView(target: target, scale: 1, model: model)
      .frame(width: target.size.width, height: target.size.height)
    )
    return renderer.nsImage
  }
}

// NSImage转PNG Data扩展
extension NSImage {
  var pngData: Data? {
    guard let tiffData = tiffRepresentation,
          let bitmapImage = NSBitmapImageRep(data: tiffData) else {
      return nil
    }
    return bitmapImage.representation(using: .png, properties: [:])
  }
}
