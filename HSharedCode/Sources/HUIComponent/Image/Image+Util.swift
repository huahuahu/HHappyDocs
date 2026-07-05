//
//  Image+Util.swift
//  HUIComponent
//
//  Created by tigerguo on 2023/3/26.
//

import Foundation

#if os(macOS)
  import AppKit

  public extension NSImage {
    func toJpegData() -> Data? {
      if let imageData = tiffRepresentation,
         let bitmapImage = NSBitmapImageRep(data: imageData),
         let jpgData = bitmapImage.representation(using: .jpeg, properties: [:]) {
        return jpgData
      }

      return nil
    }
  }

#elseif os(iOS) || os(visionOS)
  import UIKit

  public extension UIImage {
    func toJpegData() -> Data? {
      jpegData(compressionQuality: 0.8)
    }
  }

#endif
