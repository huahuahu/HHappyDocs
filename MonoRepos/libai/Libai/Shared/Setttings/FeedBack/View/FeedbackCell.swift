//
//  FeedbackCell.swift
//  Libai
//
//  Created by huahuahu on 2022/2/6.
//

import SwiftUI

struct FeedbackCell: View {
  var body: some View {
    NavigationLink {
      FeedbackView()
    } label: {
      Text("反馈")
    }
  }
}

struct FeedbackCell_Previews: PreviewProvider {
  static var previews: some View {
    FeedbackCell()
  }
}
