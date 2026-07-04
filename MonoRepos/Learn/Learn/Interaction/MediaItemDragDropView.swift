//
//  MediaItemDragDropView.swift
//  Learn
//
//  Created by tigerguo on 2023/11/14.
//

import Foundation
import HMedia
import SwiftUI

@MainActor
struct MediaItemDragDropView: View {
  @State private var mediaItem: HMediaItem?
  @State private var isDestination = false
  var body: some View {
    ScrollView {
      content
//                .padding()
        .frame(width: 400, height: 400)
        .border(isDestination ? .blue : .gray, width: 1)
        .dropDestination(for: HMediaItem.self) { items, _ in
          Log.common.info("items \(items)")

          if let item = items.first {
            mediaItem = item
          }
          return true
        } isTargeted: { isTargeted in
          Log.common.info("isTargetd \(isTargeted)")
          isDestination = isTargeted
        }
    }
  }

  @ViewBuilder
  private var content: some View {
    if let mediaItem {
      MediaItemview(mediaItem: mediaItem)
    }
    else {
      Text("NoView")
    }
  }
}
