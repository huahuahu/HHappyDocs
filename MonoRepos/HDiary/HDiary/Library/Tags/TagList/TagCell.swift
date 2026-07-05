//
//  TagCell.swift
//  HDiary
//
//  Created by tigerguo on 2023/6/18.
//

import HDiaryModel
import HFoundation
import SwiftData
import SwiftUI

struct TagCell: View {
  let tag: Tag

  var body: some View {
    HStack {
      VStack(alignment: .leading) {
        Text(tag.text)
          .font(.headline.bold())
          .foregroundStyle(.primary)
          .padding(.bottom)
        Text(DiaryStringKey.momentLabelWithNumber(tag.moments?.count ?? 0))
          .font(.callout)
          .foregroundStyle(.secondary)
      }
      Spacer()
    }
  }
}

#if DEBUG
  @available(iOS 18.0, *)
  #Preview(traits: .modifier(SampleDataModifier())) { @MainActor in
    @Previewable @Query var tags: [Tag]

    return NavigationStack {
      List(tags) { tag in
        TagCell(tag: tag)
      }
      .navigationTitle(Text(verbatim: "Tags"))
      .navigationBarTitleDisplayMode(.inline)
    }
  }
#endif
