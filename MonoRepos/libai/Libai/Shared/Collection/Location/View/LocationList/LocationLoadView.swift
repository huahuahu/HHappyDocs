//
//  LocationLoadView.swift
//  Libai (iOS)
//
//  Created by huahuahu on 2022/2/13.
//

import CoreData
import SwiftUI

@MainActor
struct LocationLoadView: View {
  @FetchRequest(sortDescriptors: [SortDescriptor(\.displayName, order: .forward)], predicate: NSPredicate(format: "isDeletedInCloud == false")) private var cdLocations: FetchedResults<CDLocation>

  @ViewBuilder
  private var content: some View {
    LocationListView(locations: cdLocations.map { Location($0) }.sorted(by: { location1, location2 in
      location1.displayName.chineseCompare(location2.displayName) == .orderedAscending
    }))
  }

  var body: some View {
    content
      .navigationTitle(PredefinedString.ancientModernLocationList)
  }
}

struct LocationLoadView_Previews: PreviewProvider {
  static var previews: some View {
    LocationLoadView()
  }
}
