//
//  MedicalSiteSection.swift
//  HDoc
//
//  Created by tigerguo on 2024/1/12.
//

import HDocAppConstants
import HDocModel
import HUIComponent
import SwiftData
import SwiftUI

extension RecordView {
  @MainActor struct MedicalSiteSection: View {
    @Bindable var record: Record
    @Query private var medicalSites: [MedicalSite]
    @State private var showSelectionView = false

    @Environment(\.modelContext) private var modelContext

    var body: some View {
      Section {
        ForEach(getSortedMedicalSites()) { site in
          NavigationLink(value: HDocNavigationTarget.medicalSite(site)) {
            Text(site.name)
          }
        }
        .onDelete(perform: deleteSite(at:))

        Button {
          showSelectionView = true
        } label: {
          Label(
            title: { Text(HDocString.Common.edit) },
            icon: { Image(hdocSymbol: .edit) }
          )
        }
        .sheet(isPresented: $showSelectionView, content: {
          editView
        })

      } header: {
        Text(HDocString.MedicalSite.medicalSite)
      }
    }

    @ViewBuilder
    private var editView: some View {
      let config = HSelectionView<MedicalSite>.Config(
        title: HDocString.Record.editMedicalSite,
        nothingSelectedText: HDocString.Common.selectFromBelow
      )
      NavigationStack {
        HSelectionView(
          allItems: medicalSites,
          initialItems: getSortedMedicalSites(),
          config: config
        ) { newItems in
          record.medicalSites = newItems
        }
      }
    }

    private func getSortedMedicalSites() -> [MedicalSite] {
      medicalSites
        .filter { staff in
          return (record.medicalSites ?? []).contains(staff)
        }
        .sorted {
          $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }

    private func deleteSite(at indexSet: IndexSet) {
      let sortedSites = getSortedMedicalSites()
      let sitesToDelete = indexSet.map { sortedSites[$0] }
      Log.data.info("delete medical sites \(sitesToDelete.map { $0.uuid.uuidString }) from record \(record.uuid)")
      record.medicalSites?.removeAll(where: { site in
        sitesToDelete.contains(site)
      })
    }
  }
}

extension MedicalSite: @retroactive HSelectionViewItem {}

#if DEBUG

  private struct PreviewContainerView: View {
    @Query private var records: [Record]

    var body: some View {
      RecordView.MedicalSiteSection(record: records[0])
    }
  }

  #Preview { @MainActor in
    NavigationStack {
      Form {
        PreviewContainerView()
      }
      .navigationTitle(Text(verbatim: "Record"))
    }
    .previewEnvironment()
  }

#endif
