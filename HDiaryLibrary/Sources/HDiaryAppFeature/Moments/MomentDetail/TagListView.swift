//
//  TagListView.swift
//  HDiary
//
//  Created by tigerguo on 2023/6/18.
//

import HDiaryModel
import HUIComponent
import SwiftData
import SwiftUI

struct TagListView: View {
  @ScaledMetric private var horizontalPadding = Design.Tag.horizontalPadding
  @ScaledMetric private var verticalPadding = Design.Tag.verticalPadding

  let tags: [Tag]

  var body: some View {
    HStack(alignment: .firstTextBaseline) {
      Image(systemName: "tag")
        .renderingMode(.original)
        .foregroundStyle(Color.accentColor)
      HFlowLayout(itemSpace: horizontalPadding, rowSpace: verticalPadding, horizontalAlignment: .leading) {
        ForEach(tags) { tag in
          NavigationLink(value: HDiaryDestination.tag(tag: tag)) {
            Text(tag.text)
              .tagStyle(.selected)
          }
        }
      }
    }
    .padding(.horizontal, 10)
  }
}

#if DEBUG
  @available(iOS 18.0, *)
  #Preview("two tags", traits: .modifier(SampleDataModifier())) {
    @Previewable @Query var tags: [Tag]
    return ScrollView {
      TagListView(tags: tags)
    }
    .tint(Color.blue)
  }

  @available(iOS 18.0, *)

  #Preview("many tags", traits: .modifier(SampleDataModifier())) {
    @Previewable @Query var tags: [Tag]
    TagListView(tags: tags)
      .tint(Color.blue)
  }
#endif
