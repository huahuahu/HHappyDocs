//
//  MaxWidth.swift
//  Libai
//
//  Created by huahuahu on 2021/12/28.
//

import SwiftUI

struct MaxWidth: View {
  var body: some View {
    Text("Please log in")
      // https://www.hackingwithswift.com/quick-start/swiftui/how-to-give-a-view-a-custom-frame
      // you could make a text view fill the whole screen (minus the safe area) by specifying a frame with zero for its minimum width and height, and infinity for its maximum width and height, like this
      .frame(minWidth: 0, maxWidth: .infinity)
      .font(.largeTitle)
      .foregroundColor(.white)
      .background(Color.red)
  }
}

struct MaxWidth_Previews: PreviewProvider {
  static var previews: some View {
    MaxWidth()
  }
}
