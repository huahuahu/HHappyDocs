//
//  HPreview.swift
//  HUIComponent
//
//  Created by tigerguo on 2023/3/26.
//
#if os(iOS)

  import QuickLook
  import SwiftUI
  import UIKit

  public struct HPreviewView: UIViewControllerRepresentable {
    public init(fileURL: URL) {
      self.fileURL = fileURL
    }

    public typealias UIViewControllerType = QLPreviewController

    public let fileURL: URL

    public func makeUIViewController(context: Context) -> QLPreviewController {
      let previewController = QLPreviewController()
      return previewController
    }

    public func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
      uiViewController.dataSource = context.coordinator
    }

    public func makeCoordinator() -> Coordinator {
      Coordinator(fileURL: fileURL)
    }

    public class Coordinator: NSObject, QLPreviewControllerDataSource {
      let fileURL: URL

      init(fileURL: URL) {
        self.fileURL = fileURL
        super.init()
      }

      public func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        // Return the number of items to preview
        return 1
      }

      public func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        // Return the item to preview
        return fileURL as QLPreviewItem
      }
    }
  }

#endif
