//
//  SymptomListView.swift
//  HDoc
//
//  Created by tigerguo on 2023/12/30.
//

import HDocAppConstants
import HDocModel
import SwiftData
import SwiftUI

@MainActor
struct SymptomListView: View {
  @Query private var symptoms: [Symptom]
  @Environment(\.modelContext) private var modelContext

  init(sortOrder: SymptomSortOrder) {
    switch sortOrder {
    case .title:
      _symptoms = Query(sort: [SortDescriptor(\Symptom.title, order: .forward)])
    case .startDate:
      _symptoms = Query(sort: [SortDescriptor(\Symptom.startDate, order: .reverse)])
    }
  }

  var body: some View {
    List {
      RecentRecordCardListView()
      if !symptoms.isEmpty {
        Section {
          ForEach(symptoms) {
            symptom in
            NavigationLink(value: HDocNavigationTarget.symptom(symptom)) {
              SymptomCellView(symptom: symptom)
            }
          }
//          .onDelete(perform: deleteSymptom)
        } header: {
          Text(HDocString.symptom)
            .bold()
            .font(.title2)
            .fontDesign(.rounded)
            .foregroundStyle(.primary)
        }
      }
    }
    .scrollIndicatorsFlash(onAppear: true)
    .scrollIndicatorsFlash(trigger: symptoms.count)
    .overlay {
      if symptoms.isEmpty {
        noSymptomView
      }
    }
  }

//  private func deleteSymptom(at indexSet: IndexSet) {
//    indexSet.forEach { index in
//      let symptom = symptoms[index]
//      modelContext.delete(symptom)
//    }
//  }

  private var noSymptomView: some View {
    ContentUnavailableView(
      String(
        localized: HDocString.Symptom.noSymptomMessage
      ),
      systemImage: HDocSymbol.circle.rawValue
    )
  }
}

#Preview { @MainActor in
  NavigationStack {
    SymptomListView(sortOrder: .title)
      .previewEnvironment()
  }
}

#Preview("Empty") { @MainActor in
  NavigationStack {
    SymptomListView(sortOrder: .title)
      .previewEnvironment()
  }
  .onAppear {
    try? HDocContainer.previewContainer.mainContext.delete(model: Symptom.self)
  }
}
