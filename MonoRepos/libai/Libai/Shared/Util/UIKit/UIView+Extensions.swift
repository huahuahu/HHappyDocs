//
//  UIView+Extensions.swift
//  Libai
//
//  Created by huahuahu on 2022/3/20.
//

import Foundation
#if canImport(UIKit)
  import UIKit

  extension UIView {
    var vc: UIViewController? {
      var parentResponder: UIResponder? = self
      while parentResponder != nil {
        parentResponder = parentResponder?.next
        if let viewController = parentResponder as? UIViewController {
          return viewController
        }
      }
      return nil
    }
  }
#endif
