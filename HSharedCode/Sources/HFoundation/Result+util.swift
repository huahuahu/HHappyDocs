//
//  Result+util.swift
//  HFoundation
//
//  Created by tigerguo on 2023/4/20.
//

import Foundation

public extension Result {
  var isSuccess: Bool {
    switch self {
    case .success:
      return true
    case .failure:
      return false
    }
  }
}
