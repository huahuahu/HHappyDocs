//
//  ContentView.swift
//  AppStoreArtWork
//
//  Created by tigerguo on 2025/3/19.
//

import SwiftUI

struct ContentView: View {
  var body: some View {
    NavigationSplitView {
      SidebarView()
    } detail: {
      DetailView()
    }
  }
}

#Preview {
  ContentView()
}
