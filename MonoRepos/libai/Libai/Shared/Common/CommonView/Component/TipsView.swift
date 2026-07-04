//
//  TipsView.swift
//  Libai
//
//  Created by huahuahu on 2022/3/12.
//

import SwiftUI

struct TipsView: View {
  let tips: String?

  var body: some View {
    tips.map {
      Text($0)
        .font(.callout)
    }
  }
}

struct TipsView_Previews: PreviewProvider {
  static var previews: some View {
    TipsView(tips: "tips")
    TipsView(tips: nil)
    TipsView(tips: "tips")
  }
}
