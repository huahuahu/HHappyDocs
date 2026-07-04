//
//  HDescriptionView.swift
//  ClipboardInspector
//
//  Created by tigerguo on 2023/3/25.
//

import SwiftUI

/// Show text of calling `String(describing:)`
struct HDescriptionView: View {
  let hDescription: HDescription
  var body: some View {
    ScrollView {
      Text(String(describing: hDescription.object))
        .padding()
    }
  }
}

struct HDescriptionView_Previews: PreviewProvider {
  static var previews: some View {
    HDescriptionView(hDescription: HDescription(object: "1"))
  }
}
