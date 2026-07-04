//
//  IndexHistory.swift
//  Learn
//
//  Created by tigerguo on 2025/1/27.
//
import Foundation
import SwiftData

extension SearchDemo {
  @available(iOS 18, *)
  enum IndexHistory {
    static func fetchHistory() async {
      do {
        // Decode the given token data.
//                let token = try JSONDecoder().decode(History.DefaultToken.self, from: tokenData)
//                // Create a history descriptor and specify the predicate.
        let descriptor = HistoryDescriptor<DefaultHistoryTransaction>()
//                descriptor.predicate = #Predicate {
//                    ($0.token > token) && ($0.author == "widget")
//                }
        // Fetch the matching history transactions.
        let context = ModelContext(IndexContainer.icloudContainer)
        let txns = try context.fetchHistory(descriptor)

        // Process the fetched transactions.
        for txn in txns {
          // Filter out any change that isn't an update.
          for change in txn.changes {
            switch change {
            case .delete(let delete):
//                            delete.if
//                logger.info("delete history: \(delete.tombs)")

              if let defaultDelete = delete as? DefaultHistoryDelete<SearchDemo.Incident> {
                print("delete search demo incident history: \(String(describing: defaultDelete.tombstone[\SearchDemo.Incident.uuid]))")
              }
              else if let personDelete = delete as? DefaultHistoryDelete<SearchDemo.Person> {
                print("delete search demo person history: tombstone \(personDelete.tombstone.map { $0 })")
              }
              else {
                print("delete search demo unknown: \(delete)")
              }
//                            delete.tombstone.forEach { element in
//                                logger.info("delete history: ")
//                                print("delete history: \(element)")
//                            }
            case .insert(let insert):
//              print("insert history: \(insert)")
              if let incidentInsert = insert as? DefaultHistoryInsert<SearchDemo.Incident> {
                print("insert search demo incident history: \(incidentInsert)")
              }
              else if let personInsert = insert as? DefaultHistoryInsert<SearchDemo.Person> {
                print("insert search demo person history: \(personInsert)")
              }
              else {
                print("insert search demo unknown: \(insert)")
              }

            case .update(let update):
//              logger.info("update history: ")
              if let incidentUpdate = update as? DefaultHistoryUpdate<SearchDemo.Incident> {
                print("update search demo incident history: \(incidentUpdate)")
                for attribute in incidentUpdate.updatedAttributes {
                  print("update search demo incident history: \(attribute)")
                }
                let changedModelID = change.changedPersistentIdentifier

                let fetchDescriptor = FetchDescriptor<SearchDemo.Incident>(predicate: #Predicate {
                  $0.persistentModelID == changedModelID
                })

//                    incidentUpdate.updatedAttributes.contains(\.title)

                do {
                  let changedIncidents = try context.fetch(fetchDescriptor)
                  print("fetch changed incident: \(changedIncidents.count)")
                  if let changedIncident = changedIncidents.first {
                    print("fetch changed incident: \(changedIncident.uuid), \(changedIncident.title)")
                  }
                }
                catch {
                  print("fetch changed incident failed: \(error)")
                }
              }
              else if let personUpdate = update as? DefaultHistoryUpdate<SearchDemo.Person> {
                print("update search demo person history: \(personUpdate)")
              }
              else {
                print("update search demo unknown: \(update)")
              }

            @unknown default:
              logger.info("unknown history:")
            }

//                        }
          }
        }
      }
      catch {
//                return .failure(error)
      }
    }
  }
}
