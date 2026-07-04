//
//  CollectionType.swift
//  Libai (iOS)
//
//  Created by huahuahu on 2022/2/13.
//

import Foundation

enum CollectionType: CaseIterable, Identifiable, Hashable {
  case fav
  case locationList
  case ageCompare
  case tag
  case wordCloud

  var id: String {
    switch self {
    case .fav: return "fav"
    case .locationList: return "locationList"
    case .ageCompare: return "ageCompare"
    case .tag: return "tag"
    case .wordCloud: return "wordCloud"
    }
  }

  var title: String {
    switch self {
    case .fav:
      return PredefinedString.favlist
    case .locationList:
      return PredefinedString.ancientModernLocationList
    case .ageCompare:
      return PredefinedString.ageCompare
    case .tag:
      return PredefinedString.tag
    case .wordCloud:
      return PredefinedString.wordCloud
    }
  }

  var systemImageName: String {
    switch self {
    case .fav:
      return SystemImage.like
    case .locationList:
      return SystemImage.location
    case .ageCompare:
      return SystemImage.ageCompare
    case .tag:
      return SystemImage.tag
    case .wordCloud:
      return SystemImage.wordCloud
    }
  }
}
