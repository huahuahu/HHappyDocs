//
//  Symbol.swift
//  SharedExifPackage
//
//  Created by tigerguo on 2025/3/7.
//
import SwiftUI

enum Symbol: String, CaseIterable {
  case promote = "sparkles"
  case settings = "gearshape"
  case addImage = "photo.badge.plus"
  case remove = "xmark"
  case share = "square.and.arrow.up"
  case saveToAlbum = "photo.on.rectangle"
  case info = "info.circle"
  case edit = "pencil"
  case save = "square.and.arrow.down"
}

extension Image {
  init(hExifSymbol symbol: Symbol) {
    self.init(systemName: symbol.rawValue)
  }
}
