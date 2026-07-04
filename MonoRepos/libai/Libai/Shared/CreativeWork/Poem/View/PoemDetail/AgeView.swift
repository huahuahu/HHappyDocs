//
//  AgeView.swift
//  Libai
//
//  Created by huahuahu on 2022/2/6.
//

import SwiftUI

struct AgeView: View {
  init(age: Int?) {
    self.age = age
  }

  let age: Int?
  var body: some View {
    if let age = age {
      Text("写于 \(age) 岁")
        .font(.subheadline)
    }
    else {
      EmptyView()
    }
  }
}

struct AgeView_Previews: PreviewProvider {
  static var previews: some View {
    AgeView(age: 20)
  }
}
