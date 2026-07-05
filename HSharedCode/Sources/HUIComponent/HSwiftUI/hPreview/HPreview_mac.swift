//
//  HPreview_mac.swift
//  HUIComponent
//
//  Created by tigerguo on 2023/3/26.
//

#if os(macOS)

  import AppKit
  import QuickLookUI
  import SwiftUI

  public struct HPreviewView: NSViewRepresentable {
    public init(fileURL: URL) {
      self.fileURL = fileURL
    }

    public let fileURL: URL

    public func makeNSView(context: Context) -> QLPreviewView {
      let previewView = QLPreviewView()
      return previewView
    }

    public func updateNSView(_ nsView: QLPreviewView, context: Context) {
      nsView.previewItem = fileURL as QLPreviewItem
    }
  }

#endif
