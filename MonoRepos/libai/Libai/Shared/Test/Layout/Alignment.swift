//
//  Alignment.swift
//  Libai
//
//  Created by huahuahu on 2021/12/28.
//

import SwiftUI

struct Alignment: View {
  var body: some View {
    VStack(alignment: .leading) {
      Text("Hello, world!")
        .alignmentGuide(.leading) { _ in -200 }

      Text("This is a longer line of text")
    }
    .background(.red)
    .frame(width: 400, height: 400)
    .background(.blue)
  }
}

struct Alignment_Previews: PreviewProvider {
  static var previews: some View {
    Alignment()
  }
}
