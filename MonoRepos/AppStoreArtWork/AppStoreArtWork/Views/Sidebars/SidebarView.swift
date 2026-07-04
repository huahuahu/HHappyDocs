//
//  SidebarView.swift
//  AppStoreArtWork
//
//  Created by tigerguo on 2025/3/19.
//

import SwiftUI

struct SidebarView: View {
  @Environment(Route.self) private var route

  var body: some View {
    @Bindable var route = route
    List(selection: $route.selectedTarget) {
      ForEach(Target.allCases) { target in
        SidebarCell(target: target)
          .tag(target)
      }
    }
  }
}

#Preview {
  NavigationSplitView {
    SidebarView()
  } detail: {
    Text(verbatim: "Detail")
  }
  .environment(Route())
}
