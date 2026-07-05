//
//  NoTagView.swift
//  HDiary
//
//  Created by tigerguo on 2023/6/18.
//

import HDiaryModel
import SwiftUI

struct NoTagView: View {
  var body: some View {
    ContentUnavailableView {
      Label(
        title: { Text(DiaryStringKey.tagEmptyViewLabel) },
        icon: { Image(systemName: "tag") }
      )
    } description: {
      Text(DiaryStringKey.tagEmptyViewDescription)
    }
  }
}

#Preview {
  NoTagView()
}
