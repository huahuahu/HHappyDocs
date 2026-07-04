//
//  PoemLocationView.swift
//  Libai
//
//  Created by huahuahu on 2022/2/6.
//

import CoreData
import SwiftUI

@MainActor
struct PoemLocationView: View {
  @FetchRequest(sortDescriptors: []) private var cdLocations: FetchedResults<CDLocation>

  let locationID: String

  init(locationID: String) {
    self.locationID = locationID
    _cdLocations = FetchRequest(sortDescriptors: [SortDescriptor(\.uniqueName, order: .forward)], predicate: NSPredicate(format: "uniqueName == %@", locationID))
  }

  @ViewBuilder
  var content: some View {
    if let location = cdLocations.first.map({ Location($0) }) {
      NavigationLink(value: location) {
        Button(location.displayName) {}
          .buttonStyle(TagButton(isSelected: false))
          .allowsHitTesting(false)
      }
    }
    else {
      ProgressView()
    }
  }

  var body: some View {
    content
  }
}

struct PoemLocationView_Previews: PreviewProvider {
  static var previews: some View {
    PoemLocationView(locationID: "安陆")
  }
}
