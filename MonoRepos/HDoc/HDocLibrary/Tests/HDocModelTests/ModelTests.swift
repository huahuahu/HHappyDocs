//
//  ModelTests.swift
//
//
//  Created by tigerguo on 2023/12/29.
//

#if os(iOS)

  @testable import HDocModel
  import SwiftData
  import XCTest

  @MainActor
  final class ModelTests: XCTestCase {
    private let container: ModelContainer = {
      let config = ModelConfiguration(isStoredInMemoryOnly: true)
      let container: ModelContainer
      do {
        container = try ModelContainer(for: MedicalStaff.self, Record.self, Symptom.self, configurations: config)
      }
      catch {
        fatalError("Failed to create container \(error)")
      }
      return container
    }()

    func testInsertion() throws {
      let doctor = MedicalStaff(name: "Tom")
      container.mainContext.insert(doctor)

      let doctorCount = try container.mainContext.fetchCount(FetchDescriptor<MedicalStaff>())
      XCTAssertEqual(doctorCount, 1)
    }
  }

#endif
