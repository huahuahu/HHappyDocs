//
//  HomeView.swift
//  ClipboardInspector
//
//  Created by tigerguo on 2023/3/17.
//

import HLocalization
import SwiftUI

/// Entry for inspector
struct HomeView: View {
  var body: some View {
    NavigationStack {
      List {
        Section(LocalizedString.sectionInspect) {
          ForEach(InspectEntry.allCases) { entry in
            NavigationLink(value: entry) {
              Text(entry.text)
            }
          }
        }

        Section(LocalizedString.sectionInteraction) {
          ForEach(InteractionItem.allCases) { item in
            NavigationLink(value: item) {
              Text(item.text)
            }
          }
        }

        Section {
          NavigationLink(HLocalizedString.setting) {
            SettingsView()
          }
        }
      }
      .clipboardNavigator()
      .navigationTitle(LocalizedString.home)
    }
  }
}

struct InspectEntryView_Previews: PreviewProvider {
  static var previews: some View {
    HomeView()
  }
}
