//
//  HImagePickerDefaultLabel.swift
//  HDiary
//
//  Created by tigerguo on 2023/6/26.
//

#if os(iOS)

import HDiaryModel
import SwiftUI

@MainActor
struct HImagePickerDefaultLabel: View {
  @ScaledMetric private var cornerRadius = 30.0
  @ScaledMetric private var verticalPadding = 5.0
  @ScaledMetric private var horizontalPadding = 15.0

  var body: some View {
    Label {
      Text(DiaryStringKey.addImage)
    } icon: {
      Image(systemName: "plus.circle")
    }
    .padding(.horizontal, horizontalPadding)
    .padding(.vertical, verticalPadding)
    .clipShape(Capsule())
    .overlay(
      RoundedRectangle(cornerRadius: cornerRadius)
        .stroke(Color.accentColor, lineWidth: 1)
    )
  }
}

#Preview {
  HImagePickerDefaultLabel()
}

#endif
