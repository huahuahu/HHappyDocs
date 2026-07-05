//
//  HRating.swift
//
//
//  Created by tigerguo on 2023/7/22.
//

import Combine
import Foundation
import SwiftUI

public enum HRating: Int, RawRepresentable, Comparable, Strideable, CaseIterable {
  public func advanced(by n: Int) -> Self {
    let targetValue = self.rawValue + n
    if targetValue < Self.minStar.rawValue {
      return Self.minStar
    }
    else if targetValue > Self.maxStar.rawValue {
      return Self.maxStar
    }
    else {
      return Self(rawValue: targetValue)!
    }
  }

  public func distance(to other: Self) -> Int {
    other.rawValue - self.rawValue
  }

  public static func < (lhs: Self, rhs: Self) -> Bool {
    lhs.rawValue < rhs.rawValue
  }

  case oneStar = 1
  case twoStars = 2
  case threeStars = 3
  case fourStars = 4
  case fiveStars = 5

  static var maxStar: Self {
    .fiveStars
  }

  static var minStar: Self {
    .oneStar
  }
}

public struct HRatingModel {
  public init(
    label: String = "",
    offImage: Image? = nil,
    onImage: Image = Image(systemName: "star.fill"),
    offColor: Color = Color.gray,
    onColor: Color = Color.yellow,
    canEdit: Bool = false
  ) {
    self.label = label
    self.offImage = offImage
    self.onImage = onImage
    self.offColor = offColor
    self.onColor = onColor
    self.canEdit = canEdit
  }

  let label: String

  let offImage: Image?
  let onImage: Image

  let offColor: Color
  let onColor: Color
  let canEdit: Bool
}

extension HRatingModel {
  static let preview = HRatingModel()
}
