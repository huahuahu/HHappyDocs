//
//  HomeView.swift
//  HDoc
//
//  Created by tigerguo on 2023/12/29.
//

import HDocModel
import SwiftData
import SwiftUI

@MainActor
struct HomeView: View {
  @Query private var symptoms: [Symptom]
  @Environment(\.modelContext) private var modelContext
//  @State private var navigationStore = NavigationStore()
  @Environment(AppRoute.self) private var appRoute

  @State private var sortOrder: SymptomSortOrder = .title
  var body: some View {
//    _ = Self._printChanges()
    @Bindable var appRoute = appRoute
    NavigationStack(path: $appRoute.homeNavigationStore.path) {
      SymptomListView(sortOrder: sortOrder)
        .navigationDestination(for: HDocNavigationTarget.self, destination: { target in
          target.getTargetView()
        })
        .navigationTitle(Text(HDocString.home))
        .toolbar {
          toolbarView
        }
    }
    .environment(appRoute.homeNavigationStore)
  }

  @ToolbarContentBuilder
  private var toolbarView: some ToolbarContent {
    ToolbarItemGroup(placement: .primaryAction) {
      Button(action: {
        addNewSymptom()
      }, label: {
        Label(
          title: { Text(HDocString.add) },
          icon: { Image(hdocSymbol: .plus) }
        )
      })

      Menu {
        Picker(selection: $sortOrder) {
          ForEach(SymptomSortOrder.allCases) { sortOrder in
            Text(sortOrder.labelInSortMenu)
              .tag(sortOrder)
          }
        } label: {
          Text(HDocString.Common.sort)
        }
      } label: {
        Label(
          title: { Text(HDocString.Common.sort) },
          icon: { Image(hdocSymbol: .sort) }
        )
      }
    }
  }

  private func addNewSymptom() {
    let symptom = Symptom(title: "", detail: "")
    modelContext.insert(symptom)
    appRoute.homeNavigationStore.path.append(HDocNavigationTarget.symptom(symptom))
  }
}

enum SymptomSortOrder: CaseIterable, Identifiable {
  var id: Self {
    self
  }

  case title
  case startDate

  var labelInSortMenu: LocalizedStringResource {
    switch self {
    case .title:
      HDocString.Common.sortByTitle
    case .startDate:
      HDocString.Common.sortByStartDate
    }
  }
}

#Preview { @MainActor in
  HomeView()
    .previewEnvironment()
}
