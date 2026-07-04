//
//  TighteningText.swift
//  Libai
//
//  Created by huahuahu on 2021/12/27.
//

import SwiftUI

struct TighteningText: View {
  var body: some View {
    VStack {
      Text("This is a wide text element")
        .font(.body)
        .frame(width: 200, height: 50, alignment: .leading)
        .lineLimit(1)
        .allowsTightening(true)

      Text("This is a wide text element")
        .font(.body)
        .frame(width: 200, height: 50, alignment: .leading)
        .lineLimit(1)
        .allowsTightening(false)
    }
  }
}

struct TighteningText_Previews: PreviewProvider {
  static var previews: some View {
    TighteningText()
  }
}
