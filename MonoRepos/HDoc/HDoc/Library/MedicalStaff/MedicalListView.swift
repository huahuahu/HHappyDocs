//
//  MedicalListView.swift
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
struct MedicalListView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(NavigationStore.self) private var navigationStore

  var body: some View {
    ListView()
      .toolbar {
        toolbarView
      }
      .navigationTitle(Text(HDocString.MedicalStaff.medicalStaff))
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
    let staff = MedicalStaff(name: "")
    modelContext.insert(staff)
    navigationStore.path.append(.medicalStaff(staff))
  }
}

@MainActor
private struct ListView: View {
  @Query(sort: [SortDescriptor(\MedicalStaff.name, order: .forward)]) private var medicalStaffs: [MedicalStaff]
  @Environment(\.modelContext) private var modelContext

  @ScaledMetric private var paddingBetweenNameAndDetail = 5.0

  var body: some View {
    List {
      ForEach(medicalStaffs) { staff in
        NavigationLink(value: HDocNavigationTarget.medicalStaff(staff)) {
          VStack(alignment: .leading, spacing: paddingBetweenNameAndDetail) {
            Text(staff.name)
              .bold()
              .font(.body)
              .foregroundStyle(.primary)
            if !staff.detail.isEmpty {
              Text(staff.detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            }
          }
        }
      }
    }
    .overlay {
      if medicalStaffs.isEmpty {
        emptyView
      }
    }
    .scrollIndicatorsFlash(onAppear: true)
    .scrollIndicatorsFlash(trigger: medicalStaffs.count)
  }

  private var emptyView: some View {
    ContentUnavailableView(
      String(
        localized: HDocString.MedicalStaff.noMedicalStaffMessage
      ),
      systemImage: HDocSymbol.circle.rawValue
    )
  }
}

#if DEBUG
  #Preview("non-empty") { @MainActor in
    NavigationStack {
      MedicalListView()
        .previewEnvironment()
    }
  }

  #Preview("empty") { @MainActor in
    NavigationStack {
      MedicalListView()
        .previewEnvironment()
    }
    .environment(\.locale, .cnMainland)
    .onAppear {
      try? HDocContainer.previewContainer.mainContext.delete(model: MedicalStaff.self)
    }
  }

#endif
