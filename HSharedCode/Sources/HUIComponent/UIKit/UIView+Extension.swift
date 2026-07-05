//
//  UIView+Extension.swift
//  HUIComponent
//
//  Created by tigerguo on 2023/4/15.
//

#if os(iOS)
  import Foundation
  import UIKit

  public extension UIView {
    func findViewController() -> UIViewController? {
      var nextResponder = self.next
      repeat {
        guard let nextResponderNonNil = nextResponder else {
          return nil
        }
        if let vc = nextResponderNonNil as? UIViewController {
          return vc
        }

        nextResponder = nextResponder?.next
      }
      while (nextResponder != nil)

      return nil
    }
  }

#endif
