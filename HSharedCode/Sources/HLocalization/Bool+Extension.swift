//
//  Bool+Extension.swift
//  HLocalization
//
//  Created by tigerguo on 2023/3/19.
//

import Foundation

public extension Bool {
  var localizedDescription: String {
    return self ? HLocalizedString.trueDescription : HLocalizedString.falseDescription
  }
}
