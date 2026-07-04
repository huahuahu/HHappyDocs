//
//  LifeState.swift
//  Libai
//
//  Created by huahuahu on 2021/12/26.
//

import CoreData
import Foundation

enum LifeStage: String, RawRepresentable, CaseIterable, Identifiable {
  // swiftlint:disable identifier_name
  case 出蜀之前
  case 初次游历
  case 安陆期间
  case 东移任城被玄宗召见之前
  case 玄宗召见
  case 赐金放还之后
  case 流寓江东
  case 幽州期间
  case 幽州之行后
  case 逃避安史之乱
  case 永王幕府
  case 被囚
  case 宋若思幕府
  case 流放夜郎
  case 暮年
  // swiftlint:disable identifier_name
  var id: String {
    rawValue
  }
}
