//
//  FavPoem.swift
//
//
//  Created by tigerguo on 2024/2/29.
//

#if os(iOS)
  import Foundation
  import SwiftData

  public typealias FavPoem = CDFavPoem
  @Model
  public final class CDFavPoem {
    public var id: Int = 0
    public var date: Date = Date()

    public init(id: Int) {
      self.id = id
      self.date = Date()
    }
  }

#endif
