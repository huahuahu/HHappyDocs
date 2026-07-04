//
//  ProseList.swift
//  Libai
//
//  Created by huahuahu on 2022/2/5.
//

import SwiftUI

struct ProseList: View {
  var body: some View {
    List(Prose.allCases) { prose in
      NavigationLink {
        ProseView(prose: prose.proseModel)
      } label: {
        Text(prose.title)
      }
    }
    .listStyle(.plain)
  }
}

struct ProseList_Previews: PreviewProvider {
  static var previews: some View {
    ProseList()
  }
}
