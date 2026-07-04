//
//  CommonColor.swift
//  Libai (iOS)
//
//  Created by huahuahu on 2022/2/7.
//

import Foundation
import SwiftUI

extension Color {
  #if os(iOS)
    static let primaryBackground = Color(UIColor.systemBackground)
    static let secondaryBackground = Color(UIColor.secondarySystemBackground)
    static let tertiaryBackground = Color(UIColor.tertiarySystemBackground)
    static let primaryGroupBackground = Color(UIColor.systemGroupedBackground)
    static let primaryLabel = Color(UIColor.label)
    static let secondaryLabel = Color(UIColor.secondaryLabel)

  #elseif os(macOS)
    static let primaryBackground = Color(NSColor.textBackgroundColor)
    static let secondaryBackground = Color(NSColor.windowBackgroundColor)
    static let tertiaryBackground = Color(NSColor.controlBackgroundColor)
    static let primaryGroupBackground = Color(NSColor.underPageBackgroundColor)
    static let primaryLabel = Color(NSColor.headerTextColor)
    static let secondaryLabel = Color(NSColor.textColor)

  #endif
}
