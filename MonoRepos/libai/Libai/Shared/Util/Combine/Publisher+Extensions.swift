//
//  Publisher+Extensions.swift
//  Libai
//
//  Created by huahuahu on 2022/3/12.
//

import Combine
import Foundation

extension Publisher where Failure == Never {
  func weakAssign<T: AnyObject>(
    to keyPath: ReferenceWritableKeyPath<T, Output>,
    on object: T
  ) -> AnyCancellable {
    sink { [weak object] value in
      object?[keyPath: keyPath] = value
    }
  }
}

//
// extension Publisher where Failure == Never {
//    func join<T: AnyObject>(
//        _ object: T
//    ) -> Publishers<(Self.Output, T)> {
//
//        map {[weak object] value in
//            if let object = object {
//                return (value, object)
//            } else {
//                throw
//            }
//        }
//    }
// }
//
