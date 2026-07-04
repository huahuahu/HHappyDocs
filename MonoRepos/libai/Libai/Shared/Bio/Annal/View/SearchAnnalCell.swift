//
//  SearchAnnalCell.swift
//  Libai (iOS)
//
//  Created by huahuahu on 2022/5/29.
//

import SwiftUI

struct SearchAnnalCell: View {
  var annal: SearchedAnnal
  var body: some View {
    VStack(alignment: .leading) {
      Text(annal.ageStr)
        .font(.title)
        .bold()
        .padding(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))

      Text(annal.empireStr)
        .fixedSize(horizontal: false, vertical: true)
        .font(.headline)
        .padding(3)

      annal.summary.map { summary in
        Text(summary)
          .fixedSize(horizontal: false, vertical: true)
          .font(.body.bold())
          .multilineTextAlignment(.leading)
          .padding([.bottom])
      }
      if let content = annal.content {
        HStack(spacing: 0) {
          Text(content.first)
            .lineLimit(1)
            .truncationMode(.head)
          Text(content.last)
            .lineLimit(1)
            .truncationMode(.tail)
        }
      }
    }
  }
}

#if DEBUG
  struct SearchedAnnalCell_Previews: PreviewProvider {
    static var previews: some View {
      SearchAnnalCell(annal: SearchedAnnal(
        id: 2,
        ageStr: AttributedString("1 岁"),
        empireStr: AttributedString("唐玄宗二十年"),
        summary: AttributedString("留在安陆"),
        content: nil,
        locationsStr: nil,
        rawAnnal: AnnalToDisplay(annal: .demo, eras: [], empires: [], locations: [])
      ))
    }
  }
#endif
