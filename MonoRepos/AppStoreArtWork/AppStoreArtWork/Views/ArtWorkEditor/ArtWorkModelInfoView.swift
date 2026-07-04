//
//  ModelInfoView.swift
//  AppStoreArtWork
//
//  Created by tigerguo on 2025/3/21.
//
import AppKit
import SwiftUI

// 新增信息视图
struct ArtWorkModelInfoView: View {
  let scale: Double
  let model: ArtWorkModel
  let target: Target

  var body: some View {
    @Bindable var model = model
    Form {
      TextField(text: $model.title) {
        Text("标题")
      }
      .textFieldStyle(.roundedBorder)

      TextField(text: $model.subtitle) {
        Text("副标题")
      }
      .textFieldStyle(.roundedBorder)

      Button("导出") {
        if let image = ExportArtImageUtil.getRenderResult(for: target, model: model) {
          saveImage(image)
        }
      }
      .padding(.top)
    }
  }

  func saveImage(_ image: NSImage) {
    let savePanel = NSSavePanel()
    let formatSelector = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 120, height: 24))
    formatSelector.addItems(withTitles: ["PNG", "JPEG", "TIFF"])

    let accessoryView = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 48))
    let label = NSTextField(labelWithString: "格式:")
    label.frame = NSRect(x: 0, y: 20, width: 50, height: 24)

    formatSelector.frame = NSRect(x: 60, y: 20, width: 120, height: 24)
    accessoryView.addSubview(label)
    accessoryView.addSubview(formatSelector)

    savePanel.accessoryView = accessoryView
    savePanel.allowedContentTypes = [.png, .jpeg, .tiff]
    savePanel.nameFieldStringValue = "export.\(formatSelector.titleOfSelectedItem?.lowercased() ?? "png")"

    formatSelector.action = #selector(NSPopUpButton.select(_:))
    formatSelector.target = savePanel

    savePanel.beginSheetModal(for: NSApp.keyWindow!) { response in
      guard response == .OK, let url = savePanel.url else { return }

      let selectedFormat = formatSelector.indexOfSelectedItem
      guard let tiffData = image.tiffRepresentation,
            let bitmapImage = NSBitmapImageRep(data: tiffData) else { return }

      switch selectedFormat {
      case 0: // PNG
        guard let data = bitmapImage.representation(using: .png, properties: [:]) else { return }
        try? data.write(to: url)
      case 1: // JPEG
        guard let data = bitmapImage.representation(using: .jpeg, properties: [.compressionFactor: 0.9]) else { return }
        try? data.write(to: url)
      case 2: // TIFF
        try? tiffData.write(to: url)
      default: break
      }
    }
  }
}

#Preview {
  ArtWorkModelInfoView(scale: 0.2, model: .getEmptyModel(), target: .sixFiveInch)
}
