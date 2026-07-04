//
//  ProseView.swift
//  Libai
//
//  Created by huahuahu on 2022/2/6.
//

import SwiftUI

struct ProseView: View {
  let prose: ProseModel
  var body: some View {
    ScrollView {
      VStack(alignment: .leading) {
        Text(prose.rawText)
          .padding()
        Text(PredefinedString.modernChineseText)
          .font(.title2)
          .bold()
          .padding(.horizontal)

        Text(prose.modernText)
          .padding()
      }
    }
    .navigationTitle(prose.title)
  }
}

struct Proseview_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      ProseView(prose: Prose.与韩荆州书.proseModel)
    }
  }
}
