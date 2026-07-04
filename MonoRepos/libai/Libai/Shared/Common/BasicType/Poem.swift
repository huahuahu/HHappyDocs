//
//  Poem.swift
//  Libai
//
//  Created by huahuahu on 2021/12/25.
//

import Foundation

/// Derived from CoreData type, used in SwiftUI
struct Poem: Codable, Identifiable, Hashable, Equatable {
  let id: Int
  let title: String
  let content: String
  let tags: [String]
  let appreciation: String?

  /// 地点的唯一ID
  let locationIds: [String]
  let genre: String?
  let age: Int?
  let plainChinese: String?
}

// Used in extension
extension Poem {
  static let demo = Poem(
    id: 215,
    title: "静夜思",
    content: [
      "窗前明月光，疑似地上霜。",
      "举头望明月，低头思故乡。",
    ].joined(separator: "\n"),
    tags: ["安陆期间", "及时行乐"],
    appreciation: "思想之行",
    locationIds: ["安陆"],
    genre: "七言古诗",
    age: 30,
    plainChinese: "在木兰为桨沙棠为舟的船上，箫管之乐在船的两头吹奏着。\n船中载着千斛美酒和美艳的歌妓，任凭它在江中随波逐流。\n黄鹤楼上的仙人还有待于乘黄鹤而仙去，而我这个海客却毫无机心地与白鸥狎游。\n屈原的词赋至今仍与日月并悬，而楚王建台榭的山丘之上如今已空无一物了。\n我兴酣之时，落笔可摇动五岳，诗成之后，啸傲之声，直凌越沧海。\n功名富贵如果能够长在，汉水恐怕就要向西北倒流了。"
  )
}

enum Genre: String, CaseIterable, Identifiable {
  // swiftlint:disable identifier_name
  case 词
  case 乐府
  case 七言古诗
  case 七言绝句
  case 七言律诗
  case 四言古诗
  case 五言古诗
  case 五言绝句
  case 五言律诗
  case 杂言古诗
  // swiftlint:enable identifier_name

  var id: String {
    rawValue
  }
}
