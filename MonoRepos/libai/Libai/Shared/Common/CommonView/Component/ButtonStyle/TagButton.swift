//
//  TagButton.swift
//  Libai
//
//  Created by huahuahu on 2022/5/31.
//

import SwiftUI

struct TagButton: ButtonStyle {
  enum BackgroundLevel {
    case primary
    case secondary
    var unselectedBackGroundColor: Color {
      switch self {
      case .primary: return Color.secondaryBackground
      case .secondary: return Color.tertiaryBackground
      }
    }
  }

  let isSelected: Bool
  let unSelectedBackgroundColor: Color

  init(isSelected: Bool, backgroundLevel: BackgroundLevel = BackgroundLevel.primary) {
    self.isSelected = isSelected
    unSelectedBackgroundColor = backgroundLevel.unselectedBackGroundColor
  }

  @ScaledMetric private var verticalPadding = 5.0
  @ScaledMetric private var horizontalPadding = 15.0
  @ScaledMetric private var cornerRadius = 30.0

  func makeBody(configuration: Configuration) -> some View {
    let backgroundColor: Color = isSelected ? .accentColor.opacity(0.2) : unSelectedBackgroundColor
    let textColor: Color = .primaryLabel
    let borderColor = isSelected ? Color.accentColor : .clear

    return configuration.label
      .padding(.vertical, verticalPadding)
      .padding(.horizontal, horizontalPadding)
      .background(backgroundColor)
      .foregroundColor(textColor)
      .clipShape(Capsule())
      .overlay(
        RoundedRectangle(cornerRadius: cornerRadius)
          .stroke(borderColor, lineWidth: 1)
      )
  }
}
