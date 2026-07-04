//
//  SearchPoemCell.swift
//  Libai
//
//  Created by huahuahu on 2022/5/30.
//

import SwiftUI

struct SearchPoemCell: View {
  let searchedPoem: SearchedPoem
  let reason: SearchMatchReason

  @ScaledMetric var padding = 10.0

  @ViewBuilder
  private var matchedContentView: some View {
    if let content = searchedPoem.content {
      HStack(spacing: 0) {
        Text(content.first)
          .lineLimit(1)
          .truncationMode(.head)
        Text(content.last)
          .lineLimit(1)
          .truncationMode(.tail)
      }
    }
  }

  @ViewBuilder
  private var titleView: some View {
    if reason.contains(.title) {
      Text(searchedPoem.title)
        .font(.headline)
    }
    else {
      Text(String(searchedPoem.title.characters))
        .font(.headline)
    }
  }

  @ViewBuilder
  private var matchedTagView: some View {
    if let tags = searchedPoem.tags, !tags.isEmpty {
      ScrollView {
        HStack {
          ForEach(0 ..< tags.count, id: \.self) { index in
            Button {} label: {
              Text(tags[index])
            }
            .buttonStyle(TagButton(isSelected: false))
          }
        }
      }
    }
    else {
      EmptyView()
    }
  }

  private var content: some View {
    VStack(alignment: .leading, spacing: padding) {
      titleView
      if reason.contains(.tag) {
        matchedTagView
      }
      if reason.contains(.content) {
        matchedContentView
      }
    }
  }

  var body: some View {
    HStack {
      NavigationLink(value: searchedPoem) {
        content
      }
    }
  }
}

struct SearchPoemCell_Previews: PreviewProvider {
  static var previews: some View {
    SearchPoemCell(searchedPoem: .demo, reason: .all)
  }
}
