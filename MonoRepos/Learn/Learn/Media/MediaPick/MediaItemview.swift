//
//  MediaItemview.swift
//  Learn
//
//  Created by tigerguo on 2023/11/12.
//

import AVKit
import HMedia
import Photos
import SwiftUI

struct MediaItemview: View {
  let mediaItem: HMediaItem

  var body: some View {
    if mediaItem.type != .movie {
      let data = mediaItem.data
      if mediaItem.type == .gif, let image = UIImage.gif(data: data) {
        GIFView(giftImage: image)
      }
      // imageReader to support gain map hdr
      else if mediaItem.type == .image, let image = UIImage.fromData(data) {
        VStack {
          Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .draggable(mediaItem)
//            .draggable(image)
          if image.isHighDynamicRange {
            Image(uiImage: image)
              .allowedDynamicRange(.high)
              .resizable()
              .scaledToFit()
              .overlay(alignment: .topLeading) {
                Text(verbatim: "HDR")
                  .fontDesign(.rounded)
//                          .visualEffect { content, geometryProxy in
//                              content.offset(x: geometryProxy.size.width / 2, y: geometryProxy.size.height / 2)
//                          }
                  .background(.regularMaterial)
              }
          }

          if let identifier = mediaItem.identifier {
            NavigationLink(value: NavigationTarget.phAsset(identifier: identifier)) {
              Text("Metadata")
            }
          }
          Text(image.isHighDynamicRange ? "HDR" : "SDR")
          Text(mediaItem.pathExtension)
        }
      }
      else {
        ContentUnavailableView(label: {
          Text("can't load")
        })
      }
    }
    else if mediaItem.type == .movie, let url = mediaItem.tempUrl {
      VideoPlayer(player: AVPlayer(url: url))
        .frame(height: 400)
        .containerRelativeFrame(.horizontal, count: 1, span: 1, spacing: 0)

//                .scaledToFit()
    }

    else {
      ContentUnavailableView(label: {
        Text("No data")
      })
    }
  }
}

#if canImport(UIKit) && DEBUG
  #Preview {
    let image = UIImage(resource: .jpegExample)
    let mediaItem = HMediaItem.fromJpegImage(image)
    return MediaItemview(mediaItem: mediaItem)
  }

#endif
