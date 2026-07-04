//
//  HDocAddMedicalSiteParkingLotView.swift
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
public struct HDocAddMedicalSiteParkingLotView: View {
  let medicalSite: MedicalSite
  @Environment(\.modelContext) private var modelContext

  public init(medicalSite: MedicalSite) {
    self.medicalSite = medicalSite
  }

  public var body: some View {
    HDocAddLocationView(favPlaceMark: .init(get: {
      medicalSite.parkingLocation.flatMap { HPlaceMark($0) }
    }, set: { placeMark in
      if let placeMark {
        let previousLocation = medicalSite.parkingLocation
        let location = ParkingLocation(name: placeMark.name, address: placeMark.address, latitude: placeMark.latitude, longitude: placeMark.longitude)
        medicalSite.parkingLocation = location
        Task { @MainActor in
          if let previousLocation {
            modelContext.delete(previousLocation)
          }
        }
      }
      else {
        let previousLocation = medicalSite.parkingLocation
        medicalSite.parkingLocation = nil
        Task { @MainActor in
          if let previousLocation {
            modelContext.delete(previousLocation)
          }
        }
      }
    }))
  }
}
