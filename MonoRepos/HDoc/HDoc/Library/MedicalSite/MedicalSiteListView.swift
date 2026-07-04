//
//  MedicalSiteListView.swift
//  HDoc
//
//  Created by tigerguo on 2024/1/5.
//

import HDocAppConstants
import HDocModel
import HFoundation
import SwiftData
import SwiftUI

@MainActor
struct MedicalSiteListView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(NavigationStore.self) private var navigationStore

  var body: some View {
    ListView()
      .toolbar {
        toolbarView
      }
      .navigationTitle(Text(HDocString.MedicalSite.medicalSite))
  }

  @ToolbarContentBuilder
  private var toolbarView: some ToolbarContent {
    ToolbarItemGroup(placement: .primaryAction) {
      Button(action: {
        addStaff()
      }, label: {
        Label(
          title: { Text(HDocString.add) },
          icon: { Image(hdocSymbol: .plus) }
        )
      })
    }
  }

  private func addStaff() {
    let site = MedicalSite(name: "")
    modelContext.insert(site)
    navigationStore.path.append(.medicalSite(site))
  }
}

@MainActor
private extension MedicalSiteListView {
  struct ListView: View {
    @Query(sort: [SortDescriptor(\MedicalSite.name, order: .forward)]) private var medicalSites: [MedicalSite]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
      List {
        ForEach(medicalSites) { medicalSite in
          NavigationLink(value: HDocNavigationTarget.medicalSite(medicalSite)) {
            Text(medicalSite.name)
          }
        }
//        .onDelete {
//          deleteSite(at: $0)
//        }
      }
      .overlay {
        if medicalSites.isEmpty {
          emptyView
        }
      }
      .scrollIndicatorsFlash(onAppear: true)
      .scrollIndicatorsFlash(trigger: medicalSites.count)
    }

    private var emptyView: some View {
      ContentUnavailableView(
        String(
          localized: HDocString.MedicalSite.noMedicalSiteMessage
        ),
        systemImage: HDocSymbol.circle.rawValue
      )
    }

//    private func deleteSite(at indexSet: IndexSet) {
//      let medicalSitesToDelete = indexSet.map {
//        medicalSites[$0]
//      }
//
//      medicalSitesToDelete.forEach {
//        modelContext.delete($0)
//      }
//    }
  }
}

#if DEBUG
  #Preview("non-empty") { @MainActor in
    NavigationStack {
      MedicalSiteListView()
        .hDocNavigator()
    }
    .previewEnvironment()
  }

  #Preview("empty") { @MainActor in
    NavigationStack {
      MedicalSiteListView()
    }
    .previewEnvironment()
    .environment(\.locale, .cnMainland)
    .onAppear {
      try? HDocContainer.previewContainer.mainContext.delete(model: MedicalSite.self)
    }
  }

#endif
