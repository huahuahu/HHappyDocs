//
//  HPreviewUrlState.swift
//  ClipboardInspector
//
//  Created by tigerguo on 2023/3/26.
//

import Combine
import Foundation
import HFoundation

/// Used as navigation value for for previewing HPasteboardItemRepresentation
class HPreviewStoreWrapper: NSObject {
  let writter: HPreviewUrlWritter
  let state: HPreviewFileURLState

  init(dataType: HDataType, state: HPreviewFileURLState) {
    self.state = state
    self.writter = HPreviewUrlWritter(hDataType: dataType, fileURLState: state)
  }
}

@MainActor
class HPreviewFileURLState: ObservableObject {
  @Published private(set) var fileURL: URL?

  func updateFileURL(_ newURL: URL?) {
    fileURL = newURL
  }
}

actor HPreviewUrlWritter {
  let hDataType: HDataType

  unowned let fileURLState: HPreviewFileURLState

  init(hDataType: HDataType, fileURLState: HPreviewFileURLState) {
    self.hDataType = hDataType
    self.fileURLState = fileURLState
  }

  func canPreview() -> Bool {
    hDataType.canPreview()
  }

  func writeToFile() async throws {
    guard await fileURLState.fileURL == nil else {
      return
    }

    var tmpUrl = URL.makeTempUrl()
    switch hDataType {
    case .data, .unknown:
      return
    case let .string(string, fileExt):
      tmpUrl = tmpUrl.appendingPathExtension(fileExt)
      try string.write(to: tmpUrl, atomically: true, encoding: .utf8)
      await fileURLState.updateFileURL(tmpUrl)
    case .image(let image):
      tmpUrl = tmpUrl.appendingPathExtension("jpeg")
      try image.toJpegData()?.write(to: tmpUrl)
      await fileURLState.updateFileURL(tmpUrl)
    }
  }
}
