//
//  MediaLearnEntry.swift
//  Learn
//
//  Created by tigerguo on 2023/11/12.
//

import Foundation
import SwiftUI

enum MediaLearnEntry: CaseIterable, Identifiable, Hashable {
  case mediaPick
  case thumbnailGenerator
  case checkMediaMetadata

  var id: Self {
    self
  }

  var title: String {
    switch self {
    case .mediaPick:
      return "Pick media (hdr and metadata)"
    case .thumbnailGenerator:
      return "Thumbnail Generator"
    case .checkMediaMetadata:
      return "Check Media Metadata without request permission"
    }
  }

  @MainActor
  @ViewBuilder var entryView: some View {
    switch self {
    case .mediaPick:
      MediaPickView()
    case .thumbnailGenerator:
      ThumbnailGenerateView()
    case .checkMediaMetadata:
      MediaMetaDataView()
    }
  }
}
