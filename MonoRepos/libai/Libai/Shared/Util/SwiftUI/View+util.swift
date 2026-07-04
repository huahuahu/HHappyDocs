//
//  View+util.swift
//  Libai (iOS)
//
//  Created by tigerguo on 2022/4/27.
//

import Foundation
import SwiftUI
#if canImport(UIKit)
  import UIKit
#endif

extension View {
  #if canImport(UIKit)

    func snapshot(_ size: CGSize? = nil) -> UIImage {
      let controller = UIHostingController(rootView: edgesIgnoringSafeArea(.all))
      let view = controller.view
//      let targetSize = controller.sizeThatFits(in: UIScreen.main.bounds.size)

      let targetSize = size ?? controller.view.intrinsicContentSize
      view?.bounds = CGRect(origin: .zero, size: targetSize)
      view?.backgroundColor = .clear

      let renderer = UIGraphicsImageRenderer(size: targetSize)

      return renderer.image { _ in
        view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
      }
    }
  #endif
}
