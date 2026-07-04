//
//  MedicalSiteView.swift
//  HDoc
//
//  Created by tigerguo on 2024/1/5.
//

import HDocLocation
import HDocModel
import HDocSharedView
import SwiftData
import SwiftUI

@MainActor
struct MedicalSiteView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(NavigationStore.self) private var navigationStore
  @Bindable var medicalSite: MedicalSite
  @State private var showDeleteAlert = false

  var body: some View {
    Form {
      nameSection
      detailSection
      deleteSection
      locationSection
    }
    .navigationTitle(Text(HDocString.detail))
  }

  private var nameSection: some View {
    Section {
      TextField(text: $medicalSite.name) {
        Text(HDocString.Common.name)
      }
    } header: {
      Text(HDocString.Common.name)
    }
  }

  private var detailSection: some View {
    Section {
      NavigationLink {
        SymptomDetailEditView(text: $medicalSite.detail)
      } label: {
        Text(medicalSite.detail.removeEmptyLines())
          .lineLimit(3)
          .truncationMode(.tail)
      }
    } header: {
      Text(HDocString.detail)
    }
  }

  private var locationSection: some View {
    Section {
      NavigationLink(value: HDocNavigationTarget.medicalSiteLocation(medicalSite)) {
        LabeledContent {
          if let location = medicalSite.location {
            Text(location.name)
          }
          else {
            Text(HDocString.MedicalSite.noLocation)
          }
        } label: {
          Label(
            title: { Text(HDocString.MedicalSite.location) },
            icon: { Image(hdocSymbol: .location) }
          )
        }
      }

      NavigationLink(value: HDocNavigationTarget.medicalSiteParkingLocation(medicalSite)) {
        LabeledContent {
          if let location = medicalSite.parkingLocation {
            Text(location.name)
          }
          else {
            Text(HDocString.MedicalSite.noLocation)
          }
        } label: {
          Label(
            title: { Text(HDocString.MedicalSite.parkingLocation) },
            icon: { Image(hdocSymbol: .car) }
          )
        }
      }
    }
  }

  private var deleteSection: some View {
    Section {
      Button(role: .destructive) {
        showDeleteAlert = true
      } label: {
        Text(HDocString.Common.delete)
          .foregroundStyle(.primary)
      }
      .alert(Text(HDocString.MedicalSite.deleteMessage), isPresented: $showDeleteAlert) {
        Button(role: .destructive) {
          deleteSite()
        } label: {
          Text(HDocString.Common.delete)
        }

        Button(role: .cancel, action: {}, label: {
          Text(HDocString.Common.cancel)
        })
      }
    }
  }

  private func deleteSite() {
    if case let .medicalSite(lastSite) = navigationStore.path.last,
       lastSite == medicalSite {
      navigationStore.path.removeLast()
    }
    modelContext.delete(medicalSite)
  }
}

#if DEBUG
  private struct PreviewContainerView: View {
    @Query private var medicalSites: [MedicalSite]
    var body: some View {
      MedicalSiteView(medicalSite: medicalSites[0])
    }
  }

  #Preview { @MainActor in
    NavigationStack {
      PreviewContainerView()
    }
    .previewEnvironment()
  }

#endif
