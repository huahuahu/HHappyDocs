//
//  AnnalState.swift
//  Libai
//
//  Created by huahuahu on 2022/1/2.
//

import CoreLocation
import Foundation
import MapKit

struct AnnalState: Equatable {
  let annalToDisplay: [AnnalToDisplay]

  init(annals: [Annal], eras: [Era], empires: [Empire], locations: [Location]) {
    let annalToDisplayd = annals.map { annal -> AnnalToDisplay in
      AnnalToDisplay(annal: annal, eras: eras, empires: empires, locations: locations)
    }

    annalToDisplay = annalToDisplayd
  }
}

struct AnnalToDisplay: Identifiable, Hashable, Equatable {
  enum Constant {
    static let birthYear = 700
  }

  private static let formatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.locale = Locale(identifier: "zh_CN")
    formatter.numberStyle = .spellOut
    return formatter
  }()

  let id: Int
  let age: Int
  let content: String
  let empireStr: String
  let locations: [Location]
  let summary: String?

  init(id: Int, age: Int, content: String, empireStr: String, locations: [Location], summary: String?) {
    self.id = id
    self.age = age
    self.content = content
    self.empireStr = empireStr
    self.locations = locations
    self.summary = summary
  }

  init(annal: Annal, eras: [Era], empires: [Empire], locations: [Location]) {
    let locationStringSet = Set(annal.locationIDs)
    let annalLocations = locations.filter { locationStringSet.contains($0.uniqueName) }
    let empireStr1: String = {
      let commonEraYear = annal.age + Constant.birthYear
      let empires = empires.filter { empire in
        empire.reignFrom <= commonEraYear && empire.reignUntil >= commonEraYear
      }

      let erasString = empires.map { empire in
        let eraString = eras.filter { era in
          era.empire == empire.templeName
        }.filter { era in
          era.starYear <= commonEraYear && era.endYear >= commonEraYear
        }
        .map { era -> String in
          let formattedYearCount: String = {
            let yearCount = commonEraYear - era.starYear + 1
            if yearCount == 1 {
              return "元"
            }
            let formatterString = Self.formatter.string(from: NSNumber(value: yearCount))
            return formatterString ?? "\(yearCount)"
          }()
          return "\(era.name)\(formattedYearCount)年 "
        }.joined(separator: " ")
        return empire.templeName + eraString
      }.joined(separator: "，")

      let commonEraString = "公元\(commonEraYear)年，"
      return commonEraString + erasString
    }()

//        dataLog("empire string", empireStr1, annalLocations)
    id = annal.id
    age = annal.age
    content = annal.content
    empireStr = empireStr1
    self.locations = annalLocations
    summary = annal.summary
//    dataLog("\(content), annal to display location \(annalLocations)")
  }

  var ID: Int { id }

  var displayTitle: String {
    "\(age)岁"
  }

  func getSummary() -> String {
    if let summary = summary {
      return summary
    }
    return content.markdownToAttributed().characters.reduce("") {
      $0.appending(String($1))
    }
  }

  func getMarkdownContent() -> String {
    print("markdown : \(content)")
    return content
  }

  func locationCenter() -> CLLocationCoordinate2D {
    print("\(locations.map(\.uniqueName))")
    if locations.isEmpty {
      return CLLocationCoordinate2D(latitude: 40, longitude: 118)
    }
    else {
      let latitude = (locations.map(\.latitude).max().unsafelyUnwrapped + locations.map(\.latitude).min().unsafelyUnwrapped) / 2
      let longtitude = (locations.map(\.longitude).max().unsafelyUnwrapped + locations.map(\.longitude).min().unsafelyUnwrapped) / 2

      return CLLocationCoordinate2D(latitude: latitude, longitude: longtitude)
    }
  }

  func mapSpan() -> MKCoordinateSpan {
    let delta = 0.5
    if locations.isEmpty || locations.count == 1 {
      return MKCoordinateSpan(latitudeDelta: delta, longitudeDelta: delta)
    }
    else {
      let latitueds = locations.map(\.latitude)
      let latitudeDelta = latitueds.max().unsafelyUnwrapped - latitueds.min().unsafelyUnwrapped + delta

      let longitude = locations.map(\.longitude)
      let longitudeDelta = longitude.max().unsafelyUnwrapped - longitude.min().unsafelyUnwrapped + delta
      print("latitudeDelta \(latitudeDelta) longitudeDelta \(longitudeDelta)")
      return MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
    }
  }
}
