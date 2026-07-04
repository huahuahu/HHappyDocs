//
//  PresentTest.swift
//  Libai (iOS)
//
//  Created by huahuahu on 2022/8/27.
//

import SwiftUI

struct PresentTest: View {
  @State private var isPresenting = false
  var body: some View {
    Button {
      isPresenting.toggle()
    } label: {
      Text("Present")
    }
    .sheet(isPresented: $isPresenting) {
      Text("Presendted")
        .statusBar(hidden: false)
    }
  }
}

struct PresentTest_Previews: PreviewProvider {
  static var previews: some View {
    PresentTest()
  }
}
