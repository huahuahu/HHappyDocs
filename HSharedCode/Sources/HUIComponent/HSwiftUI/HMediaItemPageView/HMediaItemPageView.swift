//
//  HMediaItemPageView.swift
//
//
//  Created by tigerguo on 2023/12/18.
//

import Foundation
import HFoundation
import HMedia
import QuickLook
import SwiftUI

#if canImport(UIKit)
  import UIKit

  public struct MediaItemAndThumbnail {
    public init(data: Data, pathExtension: String, thumbnail: UIImage) {
      self.data = data
      self.pathExtension = pathExtension
      self.thumbnail = thumbnail
    }

    public let data: Data
    public let pathExtension: String
    public let thumbnail: UIImage
  }

  @MainActor
  public struct HMediaItemPageView: View {
    @ScaledMetric private var gifIndicaterPadding = 5.0
    public init(itemAndThumbails: [MediaItemAndThumbnail]) {
      self.itemAndThumbails = itemAndThumbails
    }

    let itemAndThumbails: [MediaItemAndThumbnail]
    @State private var currentIndex = 0

    public var body: some View {
      TabView(selection: $currentIndex) {
        ForEach(0 ..< itemAndThumbails.count, id: \.self) { index in
          HMediaItemView(itemAndThumbail: itemAndThumbails[index])
            .tag(index)
        }
      }
      .tabViewStyle(.page)
      .indexViewStyle(.page(backgroundDisplayMode: .always))
      .overlay(alignment: .topLeading) {
        if currentIndex < itemAndThumbails.count, itemAndThumbails[currentIndex].pathExtension.lowercased() == "gif" {
          Text(verbatim: "GIF")
            .padding(gifIndicaterPadding)
            .background(.regularMaterial)
        }
      }
    }
  }

  @MainActor
  public struct HMediaItemView: View {
    public init(itemAndThumbail: MediaItemAndThumbnail) {
      self.itemAndThumbail = itemAndThumbail
    }

    let itemAndThumbail: MediaItemAndThumbnail
    @State private var localPath: URL?

    public var body: some View {
      Image(uiImage: itemAndThumbail.thumbnail)
        .allowedDynamicRange(.high)
        .resizable()
        .aspectRatio(contentMode: .fill)
        .scaledToFill()
        .onTapGesture {
          Task {
            let tempDirectory = URL.makeTempUrl().appending(path: "item")
            do {
              try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
              let tempUrl = tempDirectory.appendingPathExtension(itemAndThumbail.pathExtension)
              try itemAndThumbail.data.write(to: tempUrl)
              await MainActor.run {
                localPath = tempUrl
                commonLog.trace("Write to \(tempUrl) successed)")
              }
            }
            catch {
              commonLog.error("Write \(itemAndThumbail.pathExtension) file failed \(error)")
            }
          }
        }
        .quickLookPreview($localPath)
    }
  }

  #if DEBUG
    #Preview(body: {
      let item1 = HMediaItem.fromJpegImage(.actions)
      let item2 = HMediaItem.fromJpegImage(.add)
      let mediaAndThumbnails: [MediaItemAndThumbnail] = [
        MediaItemAndThumbnail(data: item1.data, pathExtension: item1.pathExtension, thumbnail: .actions),
        MediaItemAndThumbnail(data: item2.data, pathExtension: "Gif", thumbnail: .add),
      ]

      return HMediaItemPageView(itemAndThumbails: mediaAndThumbnails)
        .frame(height: 300)
    })

  #endif

#endif
