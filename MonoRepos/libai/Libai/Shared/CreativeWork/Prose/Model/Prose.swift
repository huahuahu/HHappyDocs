//
//  Prose.swift
//  Libai
//
//  Created by huahuahu on 2022/2/5.
//

import Foundation

enum Prose: CaseIterable, Identifiable {
  // swiftlint:disable identifier_name
  case 与韩荆州书
  case 春夜宴从弟桃花园序
  // swiftlint:enable identifier_name
  var title: String {
    switch self {
    case .与韩荆州书:
      return "与韩荆州书"
    case .春夜宴从弟桃花园序:
      return "春夜宴从弟桃花园序"
    }
  }

  var id: String {
    title
  }

  var proseModel: ProseModel {
    switch self {
    case .与韩荆州书:
      return ProseModel(
        title: title,
        rawText: String(dataSetName: "与韩荆州书"),
        modernText: String(dataSetName: "与韩荆州书译文")
      )
    case .春夜宴从弟桃花园序:
      return ProseModel(
        title: title,
        rawText: String(dataSetName: "春夜宴从弟桃花园序"),
        modernText: String(dataSetName: "春夜宴从弟桃花园序译文")
      )
    }
  }
}

struct ProseModel {
  let title: String
  let rawText: String
  let modernText: String
}
