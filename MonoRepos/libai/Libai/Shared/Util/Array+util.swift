//
//  Array+util.swift
//  Libai
//
//  Created by huahuahu on 2022/1/3.
//

import Foundation

extension Sequence where Element: AdditiveArithmetic {
  /// Returns the total sum of all elements in the sequence
  func sum() -> Element { reduce(.zero, +) }
}
