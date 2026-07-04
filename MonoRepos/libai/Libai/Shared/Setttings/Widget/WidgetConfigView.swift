//
//  WidgetConfigView.swift
//  Libai (iOS)
//
//  Created by huahuahu on 2022/5/8.
//

import AlertToast
import SwiftUI
import WidgetKit

struct WidgetConfigView: View {
  @State private var updateFinish = false
  var body: some View {
    List {
      HStack {
        Button("更新诗词") {
          WidgetCenter.shared.reloadTimelines(ofKind: HWidgetKind.poems.kind)
          updateFinish = true
        }
      }
    }
    .toast(
      isPresenting: $updateFinish,
      duration: 2,
      tapToDismiss: true
    ) {
      AlertToast(
        displayMode: .banner(.pop),
        type: .complete(.blue),
        title: PredefinedString.updateFinish
      )
    }
  }
}

struct WidgetConfigView_Previews: PreviewProvider {
  static var previews: some View {
    WidgetConfigView()
  }
}
