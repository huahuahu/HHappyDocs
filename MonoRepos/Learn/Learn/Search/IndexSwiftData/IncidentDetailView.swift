//
//  IncidentDetailView.swift
//  Learn
//
//  Created by tigerguo on 2025/1/27.
//

import SwiftData
import SwiftUI

extension SearchDemo {
  @MainActor
  struct IncidentDetailView: View {
    let incident: Incident
    @Environment(\.modelContext) private var modelContext
    @State private var editedTitle: String
    @State private var showingPersonSelector = false
    @Query private var allPeople: [SearchDemo.Person]

    init(incident: Incident) {
      self.incident = incident
      _editedTitle = State(initialValue: incident.title)
    }

    var body: some View {
      List {
        Section {
          TextField("Title", text: $editedTitle)
            .onChange(of: editedTitle) {
              incident.title = editedTitle
            }

          LabeledContent(content: {
            Text(incident.createDate, style: .date)
          }, label: {
            Text("Created Date")
          })

          LabeledContent(content: {
            Text(incident.uuid.uuidString)
              .font(.system(.caption, design: .monospaced))
          }, label: {
            Text("UUID")
          })
        } header: {
          Text(verbatim: "Basic Information")
        }

        Section("Related People") {
          if let people = incident.participants {
            ForEach(people) { person in
              HStack {
                Text(person.name)
                Spacer()
                Button(role: .destructive) {
                  incident.removeParticipant(person)
                } label: {
                  Image(systemName: "minus.circle.fill")
                    .foregroundStyle(.red)
                }
              }
            }
          }

          Button {
            showingPersonSelector = true
          } label: {
            Label("Add Person", systemImage: "person.badge.plus")
          }
        }
      }
      .navigationTitle("Incident Details")
      .navigationBarTitleDisplayMode(.inline)
      .sheet(isPresented: $showingPersonSelector) {
        NavigationStack {
          List {
            ForEach(allPeople) { person in
              Button {
                if incident.participants == nil {
                  incident.participants = []
                }
                // swiftlint:disable:next force_unwrapping
                if !incident.participants!.contains(person) {
                  incident.addParticipant(person)
                }
                showingPersonSelector = false
              } label: {
                HStack {
                  Text(person.name)
                  Spacer()
                  if incident.participants?.contains(person) == true {
                    Image(systemName: "checkmark")
                      .foregroundStyle(.blue)
                  }
                }
              }
            }
          }
          .navigationTitle("Select Person")
          .navigationBarTitleDisplayMode(.inline)
          .toolbar {
            ToolbarItem(placement: .cancellationAction) {
              Button("Done") {
                showingPersonSelector = false
              }
            }
          }
        }
        .presentationDetents([.medium])
      }
    }
  }
}

#Preview {
  let config = ModelConfiguration(isStoredInMemoryOnly: true)
  // swiftlint:disable:next force_try
  let container = try! ModelContainer(for: SearchDemo.Incident.self, configurations: config)
  let incident = SearchDemo.Incident(title: "Sample Incident")
  return NavigationStack {
    SearchDemo.IncidentDetailView(incident: incident)
  }
  .modelContainer(container)
}
