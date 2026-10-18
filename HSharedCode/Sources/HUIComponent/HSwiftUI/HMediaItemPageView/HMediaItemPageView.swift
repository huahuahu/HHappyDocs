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

    public init(itemAndThumbails: [MediaItemAndThumbnail], availableSize: CGSize) {
      self.itemAndThumbails = itemAndThumbails
      self.availableSize = availableSize
    }

    let itemAndThumbails: [MediaItemAndThumbnail]
    let availableSize: CGSize
    @State private var currentIndex = 0
    @State private var localPath: URL?

    public var body: some View {
      TabView(selection: $currentIndex) {
        ForEach(0 ..< itemAndThumbails.count, id: \.self) { index in
          HMediaItemContent(itemAndThumbail: itemAndThumbails[index], contentMode: .fit, localPath: $localPath)
            .padding(.bottom, pageIndicatorHeight)
            .accessibilityIdentifier("media-preview-\(index)")
            .tag(index)
        }
      }
      .tabViewStyle(.page)
      .indexViewStyle(.page(backgroundDisplayMode: .always))
      .frame(height: pageHeight)
      .clipped()
      .overlay(alignment: .topLeading) {
        if currentItem?.pathExtension.lowercased() == "gif" {
          Text(verbatim: "GIF")
            .padding(gifIndicaterPadding)
            .background(.regularMaterial)
        }
      }
      .onChange(of: itemAndThumbails.count) { _, count in
        currentIndex = min(currentIndex, max(0, count - 1))
      }
      // Keep presentation outside the pages, whose hosting views can change during resizing.
      .quickLookPreview($localPath)
    }

    private var currentItem: MediaItemAndThumbnail? {
      guard itemAndThumbails.indices.contains(currentIndex) else { return itemAndThumbails.first }
      return itemAndThumbails[currentIndex]
    }

    private var maximumHeight: CGFloat {
      availableSize.height.isFinite ? max(0, availableSize.height * 0.8) : 0
    }

    private var pageIndicatorHeight: CGFloat {
      itemAndThumbails.count > 1 ? min(44, maximumHeight) : 0
    }

    private var pageHeight: CGFloat {
      let width = availableSize.width.isFinite ? max(0, availableSize.width) : 0
      // Size the whole collection together so paging keeps the surrounding layout stable.
      let imageHeight = itemAndThumbails.reduce(CGFloat(80)) { height, item in
        let size = item.thumbnail.size
        let ratio = size.width > 0 && size.height > 0 ? size.width / size.height : 1
        return max(height, width / (ratio.isFinite && ratio > 0 ? ratio : 1))
      }
      // Keep panoramas tappable; fit tall images within the scroll viewport, including the page dots.
      return min(maximumHeight, imageHeight + pageIndicatorHeight)
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
      HMediaItemContent(itemAndThumbail: itemAndThumbail, contentMode: .fill, localPath: $localPath)
        .quickLookPreview($localPath)
    }
  }

  @MainActor
  private struct HMediaItemContent: View {
    let itemAndThumbail: MediaItemAndThumbnail
    let contentMode: ContentMode
    @Binding var localPath: URL?

    var body: some View {
      Image(uiImage: itemAndThumbail.thumbnail)
        .allowedDynamicRange(.high)
        .resizable()
        .aspectRatio(contentMode: contentMode)
        .frame(maxWidth: contentMode == .fit ? .infinity : nil, maxHeight: contentMode == .fit ? .infinity : nil)
        .contentShape(.rect)
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

      return GeometryReader { geometry in
        HMediaItemPageView(itemAndThumbails: mediaAndThumbnails, availableSize: geometry.size)
      }
    })

  #endif

#endif
