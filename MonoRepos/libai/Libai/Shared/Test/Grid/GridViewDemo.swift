//
//  GridViewDemo.swift
//  Libai
//
//  Created by huahuahu on 2021/12/28.
//

import SwiftUI

struct GridViewDemo: View {
  let data = (1 ... 100).map { "Item \($0)" }

  let columns = [
    // https://www.hackingwithswift.com/quick-start/swiftui/how-to-position-views-in-a-grid-using-lazyvgrid-and-lazyhgrid
    // an array of GridItem describing the layout you want
//    GridItem(.adaptive(minimum: 80)),
    GridItem(.fixed(100)),
    GridItem(.flexible()),
  ]

  var body: some View {
    ScrollView {
      LazyVGrid(columns: columns, spacing: 20) {
        ForEach(data, id: \.self) { item in
          Text(item)
        }
      }
      .padding(.horizontal)
    }
    .frame(maxHeight: 300)
  }
}

struct GridViewDemo_Previews: PreviewProvider {
  static var previews: some View {
    GridViewDemo()
  }
}
