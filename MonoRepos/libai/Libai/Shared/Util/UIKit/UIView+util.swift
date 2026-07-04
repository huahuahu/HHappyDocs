//
//  UIView+util.swift
//  Libai (iOS)
//
//  Created by huahuahu on 2022/4/25.
//

import Foundation
import UIKit

extension UIView {
  func makeScreenshot() -> UIImage {
    let renderer = UIGraphicsImageRenderer(bounds: bounds)
    return renderer.image { context in
      self.layer.render(in: context.cgContext)
    }
  }
}
