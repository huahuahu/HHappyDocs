//
//  MedicalStaffSiteSection.swift
//  HDoc
//
//  Created by tigerguo on 2025/5/11.
//

import HDocAppConstants
import HDocModel
import HUIComponent
import SwiftData
import SwiftUI

extension MedicalStaffView {
  @MainActor struct SiteSection: View {
    @ScaledMetric private var siteItemSpace = 20
    @ScaledMetric private var siteRowSpace = 10
    let medicalStaff: MedicalStaff
    let isEditable: Bool
    var body: some View {
      Section {
        content

      } header: {
        sectionHeader
      }
    }

    @ViewBuilder
    private var sectionHeader: some View {
      HStack {
        Text(HDocString.MedicalSite.medicalSite)
        Spacer()
        if isEditable {
          EditButton(medicalStaff: medicalStaff)
        }
      }
    }

    @ViewBuilder
    private var content: some View {
      if let sites = medicalStaff.sites, !sites.isEmpty {
        ForEach(sites) { site in
          siteItemView(for: site)
        }
      }
      else {
        emptyView
      }
    }

    @ViewBuilder
    private func siteItemView(for site: MedicalSite) -> some View {
      NavigationLink(value: HDocNavigationTarget.medicalSite(site)) {
        Text(site.name)
//              .tagStyle(.notSelected)
      }
    }

    private var emptyView: some View {
      ContentUnavailableView(
        String(
          localized: HDocString.MedicalSite.noMedicalSiteMessage
        ),
        systemImage: HDocSymbol.circle.rawValue
      )
    }
  }

  private struct EditButton: View {
    @Bindable var medicalStaff: MedicalStaff
    @State private var isPresentingEditView: Bool = false
    @Query private var allSites: [MedicalSite]
    var body: some View {
      Button {
        isPresentingEditView = true
      } label: {
        Label {
          Text(HDocString.Common.edit)
        } icon: {
          Image(hdocSymbol: .edit)
        }
        .labelStyle(.iconOnly)
      }
      .buttonStyle(.plain)
      .sheet(isPresented: $isPresentingEditView) {
        editView
      }
    }

    @ViewBuilder
    private var editView: some View {
      NavigationStack {
        HSelectionView(
          allItems: allSites.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending },
          initialItems: medicalStaff.sites ?? [],
          config: .init(title: HDocString.Record.editMedicalSite, nothingSelectedText: HDocString.Common.selectFromBelow)
        ) { newSites in
          medicalStaff.sites = newSites
        }
      }
    }
  }
}

@available(iOS 18, *)
#Preview(traits: .modifier(SampleDataModifier())) {
  @Previewable @Query var medicalStaffs: [MedicalStaff]
  NavigationStack {
    MedicalStaffView(medicalStaff: medicalStaffs[0], readOnlyMode: false)
  }
  .hDocNavigator()
}
