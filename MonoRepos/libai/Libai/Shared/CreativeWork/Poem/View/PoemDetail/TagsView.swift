//
//  TagsView.swift
//  Libai
//
//  Created by huahuahu on 2022/2/6.
//

import MapKit
import SwiftUI

struct TagKey: Identifiable, Hashable {
  init(tag: String) {
    self.tag = tag
  }

  var id: String {
    tag
  }

  let tag: String
}

struct TagsView: View {
  init(tags: [String]) {
    self.tags = tags
  }

  let tags: [String]

  var body: some View {
    if tags.isEmpty {
      EmptyView()
    }
    else {
      ScrollView(.horizontal, showsIndicators: false) {
        HStack {
          ForEach(tags, id: \.self) { tag in
            NavigationLink(value: TagKey(tag: tag)) {
              Button {} label: {
                Text(tag)
              }
              .buttonStyle(TagButton(isSelected: false))
              .allowsHitTesting(false)
            }
          }
        }
        .padding(.horizontal, 10)
      }
    }
  }
}

struct TagsView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      TagsView(tags: ["不遇", "赐金放还", "幽州之行", "幽州之行1", "幽州之行2", "幽州之行3", "幽州之行4", "幽州之行5", "幽州之行6", "幽州之行7", "幽州之行8"])

      TagsView(tags: ["不遇", "赐金放还", "幽州之行"])
    }
    Group {
      TagsView(tags: ["不遇", "赐金放还", "幽州之行", "幽州之行1", "幽州之行2", "幽州之行3", "幽州之行4", "幽州之行5", "幽州之行6", "幽州之行7", "幽州之行8"])

      TagsView(tags: ["不遇", "赐金放还", "幽州之行"])
    }
    .environment(\.colorScheme, .dark)
  }
}
