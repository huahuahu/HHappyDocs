//
//  LifeSpan.swift
//  Libai
//
//  Created by huahuahu on 2022/3/17.
//

import Foundation

struct LifeSpan: Equatable, Identifiable, Hashable {
  let name: String
  let birthYear: Int
  let deathYear: Int

  var id: String {
    name
  }
}

extension LifeSpan {
  static let libai = LifeSpan(name: "李白", birthYear: 701, deathYear: 762)
  static let 武则天 = LifeSpan(name: "武则天", birthYear: 624, deathYear: 705)
}
