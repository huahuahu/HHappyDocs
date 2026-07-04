//
//  PoemCell.swift
//  Libai
//
//  Created by huahuahu on 2021/12/25.
//

import SwiftUI

struct PoemCell: View {
  let poem: Poem

  var content: some View {
    HStack {
      Spacer()
      Text(poem.content)
        .lineLimit(2)
        .fixedSize(horizontal: false, vertical: true)
        .font(.body)
      Spacer()
    }
  }

  var body: some View {
    VStack(alignment: .center) {
      Text(poem.title)
        .font(.title)
        .padding(.bottom)
      content
        .padding(.bottom)
    }
  }
}

struct PoemCell_Previews: PreviewProvider {
  static var previews: some View {
    PoemCell(poem: Poem.demo)
  }
}
