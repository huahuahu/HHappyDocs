//
//  CalligraphyModel.swift
//  Libai
//
//  Created by huahuahu on 2022/2/5.
//

import Foundation

struct CalligraphyModel: Identifiable {
  let title: String
  let imageString: String
  let summary: String
  let link: String
  var id: String {
    title
  }

  static let 上阳台帖 = Self(
    title: "上阳台帖",
    imageString: "上阳台帖",
    summary: "《上阳台帖》是唐代诗人、书法家李白于天宝三年（744年）创作的纸本墨迹草书书法作品，现收藏于北京故宫博物院。",
    link: "[链接](https://www.dpm.org.cn/collection/handwriting/228280.html)"
  )
}
