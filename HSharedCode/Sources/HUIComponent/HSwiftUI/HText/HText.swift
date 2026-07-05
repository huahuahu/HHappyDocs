//
//  HText.swift
//
//
//  Created by tigerguo on 2023/9/3.
//

import Foundation
import SwiftUI

public extension Text {
  init(capitalLocalized localizedStringResource: LocalizedStringResource) {
    let string = String(localized: localizedStringResource).localizedCapitalized
    self.init(string)
  }
}
