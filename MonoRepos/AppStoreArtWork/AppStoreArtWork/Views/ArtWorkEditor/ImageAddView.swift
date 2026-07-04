//
//  ImageAddView.swift
//  AppStoreArtWork
//
//  Created by tigerguo on 2025/3/21.
//

import SwiftUI

struct ImageAddView: View {
  @State private var showAddButton = false
//  @State private var image: NSImage?
  @State private var isTargeted = false // 跟踪拖放状态
  let model: ArtWorkModel

  var body: some View {
    ZStack {
      if let image = model.image {
        Image(nsImage: image)
          .resizable()
      }
      else {
        Color.white
        Button(action: {
          showAddButton.toggle()
        }, label: {
          Image(systemName: "plus")
            .font(.system(size: 72))
        })
      }
    }
    .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers -> Bool in
      guard let provider = providers.first else { return false }

      _ = provider.loadDataRepresentation(for: .fileURL) { data, _ in
        guard let data = data,
              let url = URL(dataRepresentation: data, relativeTo: nil),
              let image = NSImage(contentsOf: url) else {
          return
        }

        DispatchQueue.main.async {
//          self.image = image
          model.image = image
        }
      }
      return true
    }
    .background(isTargeted ? Color.blue.opacity(0.3) : Color.clear) // 拖放时视觉反馈
    .animation(.easeInOut, value: isTargeted)
  }
}

#Preview {
  ImageAddView(model: .getEmptyModel())
}
