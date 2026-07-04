//
//  AnnalCell.swift
//  Libai
//
//  Created by huahuahu on 2021/12/26.
//

import SwiftUI

struct AnnalCell: View {
  let annal: AnnalToDisplay
  var body: some View {
    VStack(alignment: .leading) {
      Text("\(annal.age) 岁")
        .font(.title)
        .bold()
        .padding(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))

      Text(annal.empireStr)
        .fixedSize(horizontal: false, vertical: true)
        .font(.headline)
        .padding(3)

      Text(annal.getSummary())
        .fixedSize(horizontal: false, vertical: true)
        .font(.body)
        .multilineTextAlignment(.leading)
    }
  }
}

struct AnnalCell_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      List {
        NavigationLink {
          Text("哈哈")
        } label: {
          AnnalCell(annal: .demo)
        }
      }
    }
  }
}

extension AnnalToDisplay {
  static let demo = AnnalToDisplay(
    id: 1,
    age: 30,
    content: "来到长安",
    empireStr: "公元212你啊玄宗 开元4年,吾折天到发送到家哈哈哈哈武则天3年",
    locations: [],
    summary: "出生的发生科技发达失联客机的发生率江东父老；阿水煎豆腐"
  )
}
