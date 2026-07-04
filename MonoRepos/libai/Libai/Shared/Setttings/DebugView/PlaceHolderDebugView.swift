//
//  PlaceHolderDebugView.swift
//  Libai (iOS)
//
//  Created by huahuahu on 2022/5/8.
//

import SwiftUI
import WidgetKit

struct PlaceHolderDebugView: View {
  var body: some View {
    Text("Hello, World!")
      .redacted(reason: .privacy)
      .onAppear {
        WidgetCenter.shared.reloadTimelines(ofKind: "PoemWidget")
      }
  }
}

struct PlaceHolderDebugView_Previews: PreviewProvider {
  static var previews: some View {
    PlaceHolderDebugView()
  }
}
