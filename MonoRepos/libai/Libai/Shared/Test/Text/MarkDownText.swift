//
//  MarkDownText.swift
//  Libai
//
//  Created by huahuahu on 2021/12/27.
//

import SwiftUI

struct MarkDownText: View {
  // string attributes taking priority
  // swiftlint:disable:next force_try
  let attributedString = try! AttributedString(
    markdown: "_Hamlet_ by William Shakespeare [baidu](huahuahu-libai://baidu.com)")

  var body: some View {
    Text(attributedString)
      .font(.system(size: 12, weight: .light, design: .serif))

    //  If the view accepts the proposal but the text doesn’t fit into the available space, the view uses a combination of wrapping, tightening, scaling, and truncation to make it fit.
    Text("To be, or not to be, that is the question:")
      .frame(width: 100)
//        combining a fixed width and a line limit of 1 results in truncation for text that doesn’t fit in that space
    Text("Brevity is the soul of wit.")
      .frame(width: 100)
      .lineLimit(1)
  }
}

struct MarkDownText_Previews: PreviewProvider {
  static var previews: some View {
    MarkDownText()
  }
}
