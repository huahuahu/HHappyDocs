//
//  SidebarCell.swift
//  AppStoreArtWork
//
//  Created by tigerguo on 2025/3/19.
//

import SwiftUI

struct SidebarCell: View {
  @ScaledMetric private var spacing = 6.0
  let target: Target

  var body: some View {
    VStack(alignment: .leading, spacing: spacing) {
      Text(target.title)
        .lineLimit(nil)
        .font(.body)
        .fontWeight(.bold)

      Text(target.subTitle)
        .lineLimit(nil)
        .font(.caption)
        .multilineTextAlignment(.leading)
    }
  }
}

#Preview {
  NavigationSplitView {
    List {
      SidebarCell(target: .sixFiveInch)
    }
  } detail: {
    Text("Detail")
  }
}
