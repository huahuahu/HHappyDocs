//
//  FileImage.swift
//  SharedExifPackage
//
//  Created by tigerguo on 2025/3/8.
//
#if os(iOS)

  import CoreTransferable
  import Foundation
  import SwiftUI
  import UIKit

  // Image only supports PNG file types through its Transferable conformance. Use FileImage to support other image file type from PhotosPickerItem
  struct FileImage: Transferable, Sendable {
    let url: URL
    static var transferRepresentation: some TransferRepresentation {
      FileRepresentation(contentType: .image) { file in
        SentTransferredFile(file.url)
      } importing: { received in

        let tempSubfolderURL = AppConstant.copiedImageFolder.appendingPathComponent(UUID().uuidString, isDirectory: true)

        // Create the "temp" subfolder if it doesn't exist
        if !FileManager.default.fileExists(atPath: tempSubfolderURL.path) {
          try FileManager.default.createDirectory(at: tempSubfolderURL, withIntermediateDirectories: true, attributes: nil)
        }

        // Generate a unique file name in the "temp" subfolder
        let tempFileURL = tempSubfolderURL.appendingPathComponent(received.file.lastPathComponent)

        try FileManager.default.copyItem(at: received.file, to: tempFileURL)
        return Self(url: tempFileURL)
      }
    }
  }

#endif
