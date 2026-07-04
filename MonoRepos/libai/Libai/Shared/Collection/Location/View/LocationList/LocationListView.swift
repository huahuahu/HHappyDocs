//
//  LocationListView.swift
//  Libai (iOS)
//
//  Created by huahuahu on 2022/2/13.
//

import SwiftUI

struct LocationListView: View {
  init(locations: [Location]) {
    self.locations = locations
  }

  let locations: [Location]

  func sectionDatas() -> [SectionDataWithIndex<Location, Character>] {
    SectionDataWithIndex.sectionDataArray(from: locations) { location in
      location.displayName.getFirstCharIndex()!
    }
  }

  private func cell(for location: Location) -> some View {
    NavigationLink(value: location) {
      HStack {
        Text(location.displayName)
      }
    }
  }

  @ViewBuilder
  private func indexView(with proxy: ScrollViewProxy, containeHeight: Double) -> some View {
    let indexItems = sectionDatas().map { sectionData in
      IndexItem(displayText: String(sectionData.charIndex)) {
        proxy.scrollTo(sectionData.charIndex, anchor: .top)
      }
    }

    IndexView(
      containerHeight: .constant(containeHeight), indexItems: .constant(indexItems)
    )
    .fixedSize()

//    .background(.regularMaterial)
  }

  var body: some View {
    GeometryReader { geo in

      ScrollViewReader { proxy in
        List {
          ForEach(sectionDatas()) { sectionData in
            Section {
              ForEach(sectionData.items) { location in
                cell(for: location)
              }
            } header: {
              Text(String(sectionData.charIndex))
                .id(sectionData.charIndex)
            }
          }
        }
        .listStyle(.plain)
        .overlay(alignment: .trailing) {
          indexView(
            with: proxy,
            containeHeight: geo.size.height
          )
          //                  .border(.red, width: 3)
          .offset(x: -20, y: 0)
        }
      }
    }
  }
}

#if DEBUG
  struct LocationListView_Previews: PreviewProvider {
    static var previews: some View {
      LocationListView(locations: [.碎叶城])
    }
  }
#endif
