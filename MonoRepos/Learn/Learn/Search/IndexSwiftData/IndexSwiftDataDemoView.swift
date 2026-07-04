//
//  IndexSwiftDataDemoView.swift
//  Learn
//
//  Created by tigerguo on 2025/1/27.
//

import SwiftData
import SwiftUI

extension SearchDemo {
  @MainActor
  struct IndexSwiftDataDemoView: View {
    @Query(sort: [SortDescriptor(\Incident.createDate, order: .reverse)]) private var incidents: [SearchDemo.Incident]
    @Query(sort: [SortDescriptor(\Person.createDate, order: .reverse)]) private var people: [SearchDemo.Person]
    @Environment(\.modelContext) private var modelContext
    @State private var showingIncidentSheet = false
    @State private var showingPersonSheet = false
    @State private var newIncidentTitle = ""
    @State private var newPersonName = ""

    var body: some View {
      List {
        Section(header: Text("Incidents")) {
          ForEach(incidents) { incident in
            NavigationLink(
              destination: IncidentDetailView(incident: incident).modelContainer(IndexContainer.icloudContainer)
            ) {
              Text(verbatim: incident.title)
            }
          }
          .onDelete { indexSet in
            for index in indexSet {
              modelContext.delete(incidents[index])
            }
          }
        }

        Section(header: Text("People")) {
          ForEach(people) { person in
            Text(verbatim: person.name)
          }
        }
      }
      .navigationTitle(Text(verbatim: "Index SwiftData"))
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Menu {
            Button("Add Incident") {
              showingIncidentSheet = true
            }
            Button("Add Person") {
              showingPersonSheet = true
            }
          } label: {
            Image(systemName: "plus")
          }
        }

        ToolbarItem(placement: .navigationBarTrailing) {
          Button {
            Task {
              await fetchHistory()
            }
          } label: {
            Image(systemName: "clock.arrow.circlepath")
          }
        }
      }
      .sheet(isPresented: $showingIncidentSheet) {
        NavigationStack {
          Form {
            TextField("Incident Title", text: $newIncidentTitle)
          }
          .navigationTitle("New Incident")
          .navigationBarTitleDisplayMode(.inline)
          .toolbar {
            ToolbarItem(placement: .cancellationAction) {
              Button("Cancel") {
                showingIncidentSheet = false
              }
            }
            ToolbarItem(placement: .confirmationAction) {
              Button("Add") {
                addIncident()
                showingIncidentSheet = false
              }
              .disabled(newIncidentTitle.isEmpty)
            }
          }
        }
        .presentationDetents([.medium])
      }
      .sheet(isPresented: $showingPersonSheet) {
        NavigationStack {
          Form {
            TextField("Person Name", text: $newPersonName)
          }
          .navigationTitle("New Person")
          .navigationBarTitleDisplayMode(.inline)
          .toolbar {
            ToolbarItem(placement: .cancellationAction) {
              Button("Cancel") {
                showingPersonSheet = false
              }
            }
            ToolbarItem(placement: .confirmationAction) {
              Button("Add") {
                addPerson()
                showingPersonSheet = false
              }
              .disabled(newPersonName.isEmpty)
            }
          }
        }
        .presentationDetents([.medium])
      }
    }

    private func addIncident() {
      let incident = Incident(title: newIncidentTitle)
      modelContext.insert(incident)
    }

    private func addPerson() {
      let person = Person(name: newPersonName)
      modelContext.insert(person)
    }

    private func fetchHistory() async {
      logger.info("fetch history")
      if #available(iOS 18, *) {
        await IndexHistory.fetchHistory()
      }
      else {
        // Fallback on earlier versions
      }
    }
  }
}

#Preview(body: { @MainActor in
  SearchDemo.IndexSwiftDataDemoView()
})
