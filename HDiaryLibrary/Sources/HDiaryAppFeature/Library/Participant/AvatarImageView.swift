//
//  AvatarImageView.swift
//  HDiary
//
//  Created by tigerguo on 2023/6/25.
//

#if os(iOS)

import HDiaryConstants
import SwiftUI

struct AvatarImageView: View {
  init(size: CGFloat, image: UIImage) {
    self.size = size
    self.image = image
  }

  private let size: CGFloat
  private let image: UIImage
  var body: some View {
    VStack {
      Image(uiImage: image)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: size, height: size)
        .padding([.all], padding)
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
      Log.common.log(level: DiagnosticLogging.level(for: .debug), "Preview avatar tapped")
    })
}

#endif
