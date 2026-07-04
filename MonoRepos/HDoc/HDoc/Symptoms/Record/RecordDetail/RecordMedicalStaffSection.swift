//
//  RecordMedicalStaffSection.swift
//  HDoc
//
//  Created by tigerguo on 2024/1/6.
//

import HDocAppConstants
import HDocModel
import HUIComponent
import SwiftData
import SwiftUI

@MainActor
struct RecordMedicalStaffSection: View {
  @Bindable var record: Record
  @Query private var medicalStaffs: [MedicalStaff]
  @State private var showSelectionView = false

  @Environment(\.modelContext) private var modelContext

  var body: some View {
    Section {
      ForEach(getSortedMedicalStaffs()) { staff in
        NavigationLink(value: HDocNavigationTarget.medicalStaff(staff, readOnly: true)) {
          Text(staff.name)
        }
      }
      .onDelete(perform: deleteStaff(at:))

      Button {
        showSelectionView = true
      } label: {
        Label(
          title: { Text(HDocString.Common.edit) },
          icon: { Image(hdocSymbol: .edit) }
        )
      }
      // https://x.com/captCovalent/status/1807446326390464938
      .sheet(isPresented: $showSelectionView, content: {
        editView
      })

    } header: {
      Text(HDocString.MedicalStaff.medicalStaff)
    }
  }

  @ViewBuilder
  private var editView: some View {
    let config = HSelectionView<MedicalStaff>.Config(
      title: HDocString.Record.editMedicalStaff,
      nothingSelectedText: HDocString.Common.selectFromBelow
    )
    NavigationStack {
      HSelectionView(
        allItems: medicalStaffs,
        initialItems: getSortedMedicalStaffs(),
        config: config
      ) { newItems in
        record.medicalStaffs = newItems
      }
    }
  }

  private func getSortedMedicalStaffs() -> [MedicalStaff] {
    medicalStaffs
      .filter { staff in
        return (record.medicalStaffs ?? []).contains(staff)
      }
      .sorted {
        $0.name.localizedStandardCompare($1.name) == .orderedAscending
      }
  }

  private func deleteStaff(at indexSet: IndexSet) {
    let sortedStaffs = getSortedMedicalStaffs()
    let staffsToDelete = indexSet.map { sortedStaffs[$0] }
    Log.data.info("delete medical staff \(staffsToDelete.map { $0.uuid.uuidString }) from record \(record.uuid)")
    record.medicalStaffs?.removeAll(where: { staff in
      staffsToDelete.contains(staff)
    })
  }
}

private final class BundleLocation {}

extension MedicalStaff: @retroactive HSelectionViewItem {
  @MainActor public func makePreviewView() -> some View {
    VStack {
      Text(detail.removeEmptyLines())
        .lineLimit(nil)
        .multilineTextAlignment(.leading)
    }
    .frame(idealWidth: 300.0)
    .padding()
  }

  public var showPreview: Bool {
    !detail.isEmpty
  }
}

#if DEBUG

  private struct PreviewContainerView: View {
    @Query private var records: [Record]

    var body: some View {
      RecordMedicalStaffSection(record: records[0])
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
