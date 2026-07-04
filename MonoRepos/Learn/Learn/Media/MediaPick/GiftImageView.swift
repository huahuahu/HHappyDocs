//
//  GiftImageView.swift
//  Learn
//
//  Created by tigerguo on 2023/11/12.
//

import Foundation
import SwiftUI
import UIKit

struct GIFView: UIViewRepresentable {
  let giftImage: UIImage

  func makeUIView(context: Context) -> UIImageView {
    let imageView = UIImageView()
    imageView.contentMode = .scaleAspectFit
    return imageView
  }

  func updateUIView(_ uiView: UIImageView, context: Context) {
    uiView.image = giftImage
  }
}
