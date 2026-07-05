//
//  MediaStorageInfoView.swift
//  HDiary
//
//  Created by tigerguo on 2024/9/30.
//

import HDiaryModel
import SwiftUI

@MainActor
struct MediaStorageInfoView: View {
  enum LoadState {
    case loading
    case loadFailed
    case loadSucceed(image: UIImage)
  }

  @ScaledMetric private var textHorizontalPadding = 3.0
  @ScaledMetric private var textVerticalPadding = 1.0
  @ScaledMetric private var textOffsetX = -3.0
  @ScaledMetric private var textOffsetY = 2.0

  @State private var loadState = LoadState.loading

  let mediaItem: MediaItem
  var body: some View {
    imageView
      .task {
        await calculateImage()
      }
  }

  private func calculateImage() async {
    let thumbnailData = mediaItem.thumbnailData150px ?? mediaItem.data
    let thumbnail = await Task {
      return UIImage.fromData(thumbnailData)
    }.value
    if let thumbnail {
      loadState = .loadSucceed(image: thumbnail)
    }
    else {
      loadState = .loadFailed
    }
  }

  @ViewBuilder
  var imageView: some View {
    switch loadState {
    case .loading:
      ProgressView()
    case .loadFailed:
      EmptyView()
    case .loadSucceed(let image):
      Image(uiImage: image)
        .resizable()
        .scaledToFit()
        .overlay(alignment: .topTrailing) {
          Text((mediaItem.storageSize ?? 0).formatted(.byteCount(style: .file)))
            .font(.subheadline)
            .padding(.horizontal, textHorizontalPadding)
            .padding(.vertical, textVerticalPadding)
            .foregroundStyle(.primary)
            .background(.thickMaterial)
        }
    }
  }
}
