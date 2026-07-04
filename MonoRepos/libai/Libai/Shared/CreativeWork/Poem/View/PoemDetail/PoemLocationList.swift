//
//  PoemLocationList.swift
//  Libai
//
//  Created by huahuahu on 2022/2/6.
//

import SwiftUI

struct PoemLocationList: View {
  let locationIds: [String]

  var body: some View {
    if locationIds.isEmpty {
      EmptyView()
    }
    else {
      ScrollView(.horizontal, showsIndicators: false) {
        HStack {
          Text("相关地名")
            .padding(.horizontal)
          ForEach(locationIds.map { StringKey(str: $0) }) { key in
            PoemLocationView(locationID: key.str)
          }
        }
      }
    }
  }
}

struct PoemLocationList_Previews: PreviewProvider {
  static var previews: some View {
    PoemLocationList(locationIds: ["安陆", "成都"])
  }
}
