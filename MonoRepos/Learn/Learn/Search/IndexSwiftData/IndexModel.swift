//
//  IndexModel.swift
//  Learn
//
//  Created by tigerguo on 2025/1/27.
//

import Foundation
import SwiftData

extension SearchDemo {
  @Model
  class Incident {
    // Add preserveValueOnDeletion would crash the app? no
    @Attribute(.preserveValueOnDeletion)
    private(set) var uuid = UUID()
    var title: String = ""
    private(set) var createDate: Date = Date()

    // change from cascade to nullify would crash the app? need migration? No
    @Relationship(deleteRule: .cascade)
    var participants: [Person]? = []

    init(uuid: UUID = UUID(), title: String = "") {
      self.uuid = uuid
      self.title = title
      self.participants = participants
      createDate = Date()
    }

    func addParticipant(_ person: Person) {
      participants?.append(person)
      person.event = self
    }

    func removeParticipant(_ person: Person) {
      participants?.removeAll(where: { $0.uuid == person.uuid })
      person.event = nil
    }
  }

  @Model
  class Person {
    private(set) var uuid = UUID()
    var name: String = ""
    private(set) var createDate: Date = Date()

    var event: Incident?

    init(uuid: UUID = UUID(), name: String = "") {
      self.uuid = uuid
      self.name = name
      createDate = Date()
    }
  }
}
