//
//  PreviewButton.swift
//  ClipboardInspector
//
//  Created by tigerguo on 2023/4/11.
//

#if os(iOS) || os(visionOS)
  import Combine
  import QuickLook
  import SwiftUI
  import UIKit

  @MainActor
  public struct PreviewButton: View {
    @Environment(\.appLockEnabled) private var appLockEnabled
    @Environment(\.scenePhase) private var scenePhase

    let representation: HPasteboardItemRepresentation

    init(representation: HPasteboardItemRepresentation) {
      self.representation = representation
    }

    @State private var localPath: URL?
    public var body: some View {
      Button(action: {
        Task {
          do {
            let url = try representation.writeToTmpUrl()
            await MainActor.run {
              localPath = url
            }
          }
          catch {
            print("write to url fail \(error)")
          }
        }
      }, label: {
        Text(LocalizedString.preview)
      })
      .quickLookPreview($localPath)
      .onChange(of: scenePhase) { _, newValue in
        if appLockEnabled {
          if newValue == .background || newValue == .inactive {
            localPath = nil
          }
        }
      }
    }
  }

  private extension HPasteboardItemRepresentation {
    func writeToTmpUrl() throws -> URL? {
      var tmpUrl = URL.makeTempUrl()
      switch HDataType(self) {
      case .data, .unknown:
        return nil
      case .string(var string, let fileExt):
        tmpUrl = tmpUrl.appendingPathExtension(fileExt)
        if fileExt == "html" {
          //  如果不设置charset 为utf8，preview可能会乱码
          string = string.getUTF8Html() ?? string
        }
        try string.write(to: tmpUrl, atomically: true, encoding: .utf8)
        return tmpUrl
      case .image(let image):
        tmpUrl = tmpUrl.appendingPathExtension("jpeg")
        try image.toJpegData()?.write(to: tmpUrl)
        return tmpUrl
      }
    }
  }

#endif
