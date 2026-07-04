//
//  HDataPreviewView.swift
//  HDiary
//
//  Created by tigerguo on 2023/7/7.
//

import HDiaryConstants
import HDiaryModel
import HFoundation
import HUIComponent
import QuickLook
import SwiftUI

public struct HPreviewButton: UIViewRepresentable {
  init(item: HPreviewItem, shouldPreview: Binding<Bool>) {
    self.item = item
    self._shouldPreview = shouldPreview
  }

  let item: HPreviewItem
  @Binding var shouldPreview: Bool

  public func makeUIView(context: Context) -> HPreviewInnerView {
    return HPreviewInnerView(previewItem: item, shouldPreview: $shouldPreview)
  }

  public func updateUIView(_ button: HPreviewInnerView, context: Context) {
    button.onShouldPreviewChange(self.shouldPreview)
  }

  public final class HPreviewInnerView: UIView, QLPreviewItem, QLPreviewControllerDataSource, QLPreviewControllerDelegate {
    public var previewItemURL: URL?

    private let previewItem: HPreviewItem
    @Binding var shouldPreview: Bool

    fileprivate init(previewItem: HPreviewItem, shouldPreview: Binding<Bool>) {
      self.previewItem = previewItem
      self._shouldPreview = shouldPreview
      super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    func onShouldPreviewChange(_ shouldPreview: Bool) {
      guard shouldPreview else {
        return
      }
      if previewItemURL == nil {
        previewItemURL = try? writeToTmp()
      }

      let qlVC = QLPreviewController()
      qlVC.dataSource = self
      qlVC.delegate = self
      if let vc = self.findViewController() {
        vc.present(qlVC, animated: true)
      }
    }

    private func writeToTmp() throws -> URL {
      let tmpUrl = URL.makeTempUrl().appendingPathExtension(previewItem.previewType.fileExtension)
      try previewItem.data.write(to: tmpUrl)
      return tmpUrl
    }

    public func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
      return 1
    }

    public func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
      self
    }

    public func previewController(_ controller: QLPreviewController, transitionViewFor item: QLPreviewItem) -> UIView? {
      self
    }

    public func previewControllerDidDismiss(_ controller: QLPreviewController) {
      self.shouldPreview = false
    }
  }
}

public enum HPreviewItemType {
  case jpegImage
  case heicImage
  case pngImage

  case html
  case plainText
  case gif

  var fileExtension: String {
    switch self {
    case .jpegImage:
      return "jpeg"
    case .heicImage:
      return "heic"
    case .pngImage:
      return "png"
    case .html:
      return "html"
    case .plainText:
      return "txt"
    case .gif:
      return "gif"
    }
  }
}

public struct HPreviewItem {
  let data: Data
  let previewType: HPreviewItemType

  init(data: Data, previewType: HPreviewItemType) {
    self.data = data
    self.previewType = previewType
  }

  init(_ image: UIImage) {
    if let data = image.heicData() {
      self.data = data
      previewType = .heicImage
    }
    else if let data = image.toJpegData() {
      self.data = data
      previewType = .jpegImage
    }
    else if let data = image.pngData() {
      self.data = data
      previewType = .pngImage
    }
    else {
      Log.common.error("Can't get data from image")
      fatalError("Can't get data from image")
    }
  }
}

#if DEBUG
  extension HPreviewItem {
    static let heicDemo = HPreviewItem(data: UIImage.test1.heicData().unsafelyUnwrapped, previewType: .heicImage)
  }
#endif

// #Preview {
//    HPreviewButton(item: .heicDemo, shouldPreview: .constant(false))
// }
