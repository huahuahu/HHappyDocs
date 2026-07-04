//
//  HDocAddMedicalSiteLocationView.swift
//
//
//  Created by tigerguo on 2024/9/1.
//

import Foundation
import HDocLocation
import HDocModel
import SwiftData
import SwiftUI

@MainActor
public struct HDocAddMedicalSiteLocationView: View {
  let medicalSite: MedicalSite
  @Environment(\.modelContext) private var modelContext

  public init(medicalSite: MedicalSite) {
    self.medicalSite = medicalSite
  }

  public var body: some View {
    HDocAddLocationView(favPlaceMark: .init(get: {
      medicalSite.location.flatMap { HPlaceMark($0) }
    }, set: { placeMark in
      if let placeMark {
        let previousLocation = medicalSite.location
        let location = Location(name: placeMark.name, address: placeMark.address, latitude: placeMark.latitude, longitude: placeMark.longitude)
        medicalSite.location = location
        Task { @MainActor in
          if let previousLocation {
            modelContext.delete(previousLocation)
          }
        }
      }
      else {
        let previousLocation = medicalSite.location
        medicalSite.location = nil
        Task { @MainActor in
          if let previousLocation {
            modelContext.delete(previousLocation)
          }
        }
      }
    }))
  }
}
