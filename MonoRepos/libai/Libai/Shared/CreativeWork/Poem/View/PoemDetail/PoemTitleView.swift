//
//  PoemTitleView.swift
//  Libai
//
//  Created by huahuahu on 2022/2/6.
//

import SwiftUI

struct PoemTitleView: View {
  let title: String
  var body: some View {
    HStack {
      Spacer()
      Text(title)
        .font(.title)
        .padding(.horizontal)
        .multilineTextAlignment(.leading)
      Spacer()
    }
  }
}

struct PoemTitleView_Previews: PreviewProvider {
  static var previews: some View {
    PoemTitleView(title: "静夜思")
  }
}
