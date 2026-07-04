//
//  PoemModernChineseView.swift
//  Libai
//
//  Created by huahuahu on 2022/2/6.
//

import SwiftUI

struct PoemModernChineseView: View {
  let modernChinese: String?
  var body: some View {
    if let modernChinese = modernChinese {
      VStack(alignment: .leading) {
        Text(PredefinedString.modernChineseText)
          .font(.subheadline)
          .bold()
          .padding()
        Text(modernChinese)
          .font(.body)
          .padding(.horizontal)
      }
    }
    else {
      EmptyView()
    }
  }
}

struct PoemModernChineseView_Previews: PreviewProvider {
  static var previews: some View {
    PoemModernChineseView(modernChinese: "窗前明月光")
  }
}
