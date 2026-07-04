//
//  WaterFlowButtonViewDebug.swift
//  Libai (iOS)
//
//  Created by tigerguo on 2022/4/28.
//

import SwiftUI

struct WaterFlowButtonViewDebug: View {
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

  @State var tappedText = Set<String>()

//  let config =

  var body: some View {
    GeometryReader { proxy in
      WaterFlowButtonView(
        items: texts.map { text in
          WaterFlowButtonView.Item(text: text, selected: tappedText.contains(text)) {
            hLog("tapped \(text)", scenerio: .default)
            if tappedText.contains(text) {
              tappedText.remove(text)
            }
            else {
              tappedText.insert(text)
            }
          }
        },
        config: WaterFlowButtonView.Config(
          verticalPadding: 5,
          padding: 15,
          margin: 30,
          font: UIFont.preferredFont(forTextStyle: .body),
          containerWidth: proxy.size.width,
          textColor: .primary,
          selectedTextColor: .blue,
          backgroundColor: .gray.opacity(0.3),
          selectedBackgroundColor: .blue.opacity(0.2),
          borderColor: .clear,
          selectedBorderColor: .blue
        )
      )
    }
    .padding([.horizontal])
  }
}

struct WaterFlowButtonViewDebug_Previews: PreviewProvider {
  static var previews: some View {
    WaterFlowButtonViewDebug()
  }
}
