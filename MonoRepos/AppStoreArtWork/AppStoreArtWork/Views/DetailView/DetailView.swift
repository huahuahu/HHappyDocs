//
//  DetailView.swift
//  AppStoreArtWork
//
//  Created by tigerguo on 2025/3/19.
//

import SwiftUI

struct DetailView: View {
  @Environment(Route.self) private var route
  var body: some View {
    if let target = route.selectedTarget {
      ArtWorkContainerView(target: target)
    }
    else {
      ContentUnavailableView {
        Text(verbatim: "No selection")
      }
    }
  }
}

#Preview {
  NavigationSplitView {
    SidebarView()
  } detail: {
    DetailView()
  }
  .environment(Route())
}
