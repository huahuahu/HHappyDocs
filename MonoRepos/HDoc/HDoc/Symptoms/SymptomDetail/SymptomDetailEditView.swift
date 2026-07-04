//
//  SymptomDetailEditView.swift
//  HDoc
//
//  Created by tigerguo on 2023/12/29.
//

import HDocSharedView
import SwiftUI

@MainActor
struct SymptomDetailEditView: View {
  @Binding var text: String
  var body: some View {
    HDocEditView(text: $text)
      .autocorrectionDisabled(false)
      .navigationTitle(Text(HDocString.detail))
      .navigationBarTitleDisplayMode(.inline)
  }
}

private struct PreviewContainerView: View {
  @State private var text = ""
  var body: some View {
    SymptomDetailEditView(text: $text)
  }
}

#Preview {
  NavigationStack {
    PreviewContainerView()
  }
}
