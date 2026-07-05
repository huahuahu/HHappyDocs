//
//  AvatarImageView.swift
//  HDiary
//
//  Created by tigerguo on 2023/6/25.
//

import SwiftUI

struct AvatarImageView: View {
  init(size: CGFloat, image: UIImage, supportPreview: Bool = false) {
    self.size = size
    self.image = image
    self.supportPreview = supportPreview
  }

  private let size: CGFloat
  private let image: UIImage
  private let supportPreview: Bool
  @State private var isPreviewingAvatar = false
  var body: some View {
    VStack {
      Image(uiImage: image)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: size, height: size)
        .padding([.all], padding)
        .overlay(content: {
          if supportPreview {
            HPreviewButton(item: HPreviewItem(image), shouldPreview: $isPreviewingAvatar)
              .onTapGesture {
                isPreviewingAvatar = true
              }
          }
        })
        .overlay(content: {
          RoundedRectangle(cornerRadius: radius, style: .continuous)
            .strokeBorder(Color.accentColor, lineWidth: padding)
        }
        )
    }
  }

  private var padding: CGFloat {
    max(size / 25, 2)
  }

  private var radius: CGFloat {
    max(size / 5, 5)
  }
}

#Preview("NoPreview") {
  AvatarImageView(size: 50, image: UIImage(resource: .defaultPerson))
    .onTapGesture(perform: {
      print("tapped")
    })
}

#Preview("Preview") {
  AvatarImageView(
    size: 50,
    image: UIImage(resource: .defaultPerson),
    supportPreview: true
  )
}
