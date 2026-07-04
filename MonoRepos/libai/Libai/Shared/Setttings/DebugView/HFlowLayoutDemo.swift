//
//  HFlowLayoutDemo.swift
//  Libai (iOS)
//
//  Created by huahuahu on 2022/8/27.
//

import HUIComponent
import SwiftUI

struct HFlowLayoutDemo: View {
  let texts = [
    "this is",
    "啦啦啦",
    "hallo",
    "1",
    "得到的",
    "好喽",
    "你好",
    "this is1",
    "啦啦啦1",
    "hallo1",
    "得到的1",
    "好喽1",
    "你好1",
  ]

  var body: some View {
//        HStack {
//            ForEach(texts, id: \.self) { text in
//                Text(text)
//            }
//        }
//        ViewThatFits {
    HFlowLayout(itemSpace: 20, rowSpace: 40) {
      ForEach(texts, id: \.self) { text in
        Text(text)
          .background(.red)
      }
    }
    .padding()
//        }
  }
}

struct HFlowLayoutDemo_Previews: PreviewProvider {
  static var previews: some View {
    HFlowLayoutDemo()
  }
}
