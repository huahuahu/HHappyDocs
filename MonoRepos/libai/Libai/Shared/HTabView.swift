//
//  HTabView.swift
//  Shared
//
//  Created by huahuahu on 2021/12/25.
//

import SwiftUI

@MainActor
struct HTabView: View {
//  @SceneStorage("selectedTab") var selectedTab = Tab.poems {
//    didSet {
//      hLog("selected tab become \(selectedTab)")
//    }
//  }

  @EnvironmentObject var navigationModel: HNavigationModel

  @StateObject private var urlHanlder = DeepLinkHandler()

  var body: some View {
    TabView(selection: .init(get: {
      navigationModel.selectedTab
    }, set: { newTab in
      navigationModel.selectedTab = newTab
    })) {
      BioView()
        .tabItem {
          Label("生平", systemImage: SystemImage.person)
        }.tag(Tab.annal)

      CreativeWorkView()
        .tabItem {
          Label("作品", systemImage: SystemImage.book)
        }
        .tag(Tab.poems)

      CollectionView()
        .tabItem {
          Label("专题", systemImage: SystemImage.collection)
        }
        .tag(Tab.collections)

      SettingsView()
        .tabItem {
          Label("设置", systemImage: SystemImage.gear)
        }
        .tag(Tab.settings)
    }
    .onOpenURL { url in
      urlHanlder.setNavigationModel(navigationModel)
      urlHanlder.setLatestUrl(url)
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    HTabView()
      .environmentObject(HNavigationModel())
  }
}
