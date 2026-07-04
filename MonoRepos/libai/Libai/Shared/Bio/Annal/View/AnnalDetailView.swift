//
//  AnnalDetailView.swift
//  Libai
//
//  Created by huahuahu on 2022/1/3.
//

import CoreData
import MapKit
import SwiftUI

@MainActor
struct AnnalDetailView: View {
  enum Constants {
    static let hightLightMapColor = Color.accentColor
    static let normalMapColor = Color.blue
  }

  let annalToDisplay: AnnalToDisplay
  @State private var selectedLocation: Location?
  @FetchRequest(sortDescriptors: []) private var poemsInThisYear: FetchedResults<CDPoem>

  init(annalToDisplay: AnnalToDisplay) {
    self.annalToDisplay = annalToDisplay

    _poemsInThisYear = FetchRequest<CDPoem>(
      sortDescriptors: [SortDescriptor(\.title, order: .forward)],
      predicate: NSPredicate(format: "age == %d", annalToDisplay.age)
    )
  }

  @ViewBuilder
  func mapView(annalToDisplay: AnnalToDisplay) -> some View {
    if annalToDisplay.locations.isEmpty {
      EmptyView()
    }
    else {
      Map(bounds: MapCameraBounds(centerCoordinateBounds: MKCoordinateRegion(
        center: annalToDisplay.locationCenter(),
        span: annalToDisplay.mapSpan()
      ))) {
        ForEach(annalToDisplay.locations.indices, id: \.self) { innerIndex in
          Marker(coordinate: annalToDisplay.locations[innerIndex].coordinate, label: {
            EmptyView()
          })
          .tint(selectedLocation == annalToDisplay.locations[innerIndex] ? Constants.hightLightMapColor : Constants.normalMapColor)
        }
      }
      .edgesIgnoringSafeArea(.horizontal)
      .frame(height: 300)
    }
  }

  @ViewBuilder
  func annalView(annalToDisplay: AnnalToDisplay) -> some View {
    ScrollView {
      VStack {
        Text(annalToDisplay.empireStr)
          .font(.title3)
          .lineLimit(nil)
          .padding(.vertical, 10)
          .padding(.horizontal)

        Text(annalToDisplay.getMarkdownContent().trimmingCharacters(in: .whitespacesAndNewlines).markdownToAttributed())
          .font(.body)
          .lineLimit(nil)
          .padding(.vertical, 10)
          .padding(.horizontal)

        mapView(annalToDisplay: annalToDisplay)

        PoemTitleList(poems: poemsInThisYear.map { Poem($0) }.sorted { $0.title.chineseCompare($1.title) == .orderedAscending })
      }
      .environment(\.openURL, OpenURLAction { url in
        guard let pattern = URLHandler.Pattern(url: url),
              pattern.host == .location
        else {
          hLog("can't get pattern from \(url)")
          return .systemAction
        }
        selectedLocation = annalToDisplay.locations.first { $0.uniqueName == pattern.value }
        return .handled

      })
    }
  }

  @ViewBuilder
  var content: some View {
    annalView(annalToDisplay: annalToDisplay)
  }

  var body: some View {
    content
      .navigationTitle(annalToDisplay.displayTitle)
  }
}

struct AnnalDetail_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      AnnalDetailView(annalToDisplay: .demo)
    }
  }
}

extension Location: Identifiable {
  var id: String {
    uniqueName
  }

  var coordinate: CLLocationCoordinate2D {
    CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
  }
}
