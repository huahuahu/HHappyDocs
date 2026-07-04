//
//  Target.swift
//  AppStoreArtWork
//
//  Created by tigerguo on 2025/3/19.
//

import Foundation
import SwiftUI

enum Target: CaseIterable, Identifiable, Codable {
  case sixNineInch
  case sixFiveInch
  case thirteenInch

  var id: Self {
    self
  }

  var title: String {
    switch self {
    case .sixNineInch:
      return #"6.9" Display"#
    case .sixFiveInch:
      return #"6.5" Display"#
    case .thirteenInch:
      return #"13" Display"#
    }
  }

  var subTitle: String {
    switch self {
    case .sixNineInch:
      return "2868 x 1320 px, iPhone 16 pro max for example"
    case .sixFiveInch:
      return "2778 × 1284 px, iPhone 13 Pro Max for example"
    case .thirteenInch:
      return "2752 x 2064 px, 13-inch iPad Pro for example"
    }
  }

  var size: CGSize {
    switch self {
    case .sixNineInch:
      return CGSize(width: 1320, height: 2868)
    case .sixFiveInch:
      return CGSize(width: 1284, height: 2778)
    case .thirteenInch:
      return CGSize(width: 2064, height: 2752)
    }
  }

  var bezel: ImageResource {
    switch self {
    case .sixFiveInch:
      return ImageResource.Bezel._65Inch
    case .sixNineInch:
      return ImageResource.Bezel._65Inch
    case .thirteenInch:
      return ImageResource.Bezel._13Inch
    }
  }

  var bezelSize: CGSize {
    switch self {
    case .sixFiveInch:
      return CGSize(width: 1464, height: 2978)
    case .sixNineInch:
      return CGSize(width: 1470, height: 3000)
    case .thirteenInch:
      return CGSize(width: 2300, height: 3000)
    }
  }

  var cornerSize: CGSize {
    switch self {
    case .sixFiveInch:
      return CGSize(width: 90, height: 90)
    case .sixNineInch:
      return CGSize(width: 90, height: 90)
    case .thirteenInch:
      return CGSize(width: 50, height: 50)
    }
  }
}
