//
//  SystemImage.swift
//  Libai (iOS)
//
//  Created by huahuahu on 2022/2/13.
//

import Foundation
import SwiftUI

enum SystemImage: String {
  static let add = "plus.circle"
  static let book = "book"
  static let person = "person"
  static let gear = "gear"
  static let collection = "circle.grid.cross"
  static let like = "heart.fill"
  static let unlike = "heart"
  static let folder = "folder"
  static let location = "location.circle"
  static let cloud = "cloud"
  static let figureStand = "figure.stand.line.dotted.figure.stand"
  static let ageCompare = figureStand
  static let tag = "tag"
  static let wordCloud = "magazine"
  static let share = "square.and.arrow.up"
  static let refresh = "arrow.clockwise"
  case sort = "arrow.up.arrow.down"
  case date = "calendar"
  case character
}

extension Image {
  init(systemImage: SystemImage) {
    self.init(systemName: systemImage.rawValue)
  }
}
