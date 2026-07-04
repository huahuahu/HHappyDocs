//
//  AnnalView.swift
//  Libai
//
//  Created by huahuahu on 2021/12/25.
//

import SwiftUI

@MainActor
struct AnnalView: View {
  @FetchRequest(sortDescriptors: [SortDescriptor(\.age, order: .forward)]) private var annals: FetchedResults<CDAnnal>
  @FetchRequest(sortDescriptors: [SortDescriptor(\.reignFrom, order: .forward)]) private var empires: FetchedResults<CDEmpire>
  @FetchRequest(sortDescriptors: [SortDescriptor(\.id, order: .forward)]) private var eras: FetchedResults<CDEra>
  @FetchRequest(sortDescriptors: [SortDescriptor(\.displayName, order: .forward)]) private var locations: FetchedResults<CDLocation>

  @State private var selectedAnnalID: Int?
  @State private var searchText: String = ""

  func annalList(annals: [AnnalToDisplay]) -> some View {
    ScrollViewReader { proxy in
      List {
        Text(BioType.annal.summary)
          .listRowSeparator(.hidden)
        ForEach(annals) { annal in
          NavigationLink(value: annal) {
            AnnalCell(annal: annal)
          }
        }
      }
      .listStyle(.plain)
      .onChange(of: selectedAnnalID) { _, newID in
        if let newID = newID {
          proxy.scrollTo(newID)
        }
      }
    }
  }

  @ViewBuilder
  private func searchAndContent() -> some View {
    if let searchResults = AnnalSearchEngine.searchResult(for: searchText, in: annalsToDisplay) {
      searchList(searchResults)
    }
    else {
      annalList(annals: annalsToDisplay)
    }
  }

  @ViewBuilder
  private func searchList(_ annals: [SearchedAnnal]) -> some View {
    List {
      ForEach(annals) { annal in
        NavigationLink(value: annal) {
          SearchAnnalCell(annal: annal)
        }
      }
    }
    .listStyle(.plain)
    .navigationDestination(for: SearchedAnnal.self) { searchedAnnal in
      AnnalDetailView(annalToDisplay: searchedAnnal.rawAnnal)
    }
  }

  private var annalsToDisplay: [AnnalToDisplay] {
    AnnalState(
      annals: annals.map { Annal($0) },
      eras: eras.map { Era($0) },
      empires: empires.map { Empire($0) },
      locations: locations.map { Location($0) }
    ).annalToDisplay
  }

  @ViewBuilder
  var content: some View {
    searchAndContent()
      .searchable(
        text: $searchText,
        placement: .navigationBarDrawer(displayMode: .always),
        prompt: PredefinedString.searchAnnal
      )
  }

  var body: some View {
    content
      .onOpenURL { url in
        hLog("annal list open \(url)")
        guard let pattern = URLHandler.Pattern(url: url) else {
          return
        }

        if pattern.host == .annalDetail,
           let annalIDString = pattern.value,
           let annalID = Int(annalIDString) {
          hLog("selected id is \(annalID)")
          withAnimation {
            selectedAnnalID = annalID
          }
        }
      }
  }
}

struct AnnalView_Previews: PreviewProvider {
  static var previews: some View {
    AnnalView()
  }
}
