//
//  DBName.swift
//  Libai
//
//  Created by huahuahu on 2022/3/5.
//

import Foundation

enum DBAaction: CaseIterable, Identifiable, Hashable {
  case check
  case upload

  var titleInCell: String {
    switch self {
    case .check:
      return "check"
    case .upload:
      return "upload"
    }
  }

  var id: String {
    titleInCell
  }
}
