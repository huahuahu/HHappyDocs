//
//  PoemTitleList.swift
//  Libai
//
//  Created by huahuahu on 2022/2/5.
//

import SwiftUI

struct PoemTitleList: View {
  let poems: [Poem]
  func poemTitleView(_ poem: Poem) -> some View {
    NavigationLink(value: poem) {
      Text(poem.title)
        .font(.body)
        .multilineTextAlignment(.leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 2)
        .foregroundColor(.primaryLabel)
        .background(Color.secondaryBackground)
        .cornerRadius(10)
    }
  }

  var body: some View {
    if poems.isEmpty {
      EmptyView()
    }
    else {
      HStack {
        VStack(alignment: .leading) {
          Text("作品")
            .font(.title3)
            .bold()
          ForEach(poems) { poem in
            poemTitleView(poem)
          }
        }
        .padding()
        Spacer()
      }
    }
  }
}

struct PoemTitleList_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      PoemTitleList(poems: [.demo])
    }
  }
}
