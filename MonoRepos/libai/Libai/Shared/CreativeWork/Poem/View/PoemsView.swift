//
//  PoemsView.swift
//  Libai
//
//  Created by huahuahu on 2021/12/25.
//

import CoreData
import SwiftUI

@MainActor
struct PoemsView: View {
  @State private var poemsViewStore = PoemsViewStore()
  @State var selectedGenre: String?

  @FetchRequest(sortDescriptors: []) private var cdPoems: FetchedResults<CDPoem>

  func toolBar() -> some View {
    HStack {
      PoemFilterView(selectedGenre: Binding(get: {
        poemsViewStore.selectedGenre ?? FilterModel.Constants.allGenres
      }, set: { newValue in
        if newValue == FilterModel.Constants.allGenres {
          poemsViewStore.selectedGenre = nil
        }
        else {
          poemsViewStore.selectedGenre = newValue
        }
      }), allGenres: poemsViewStore.allGenres)
      Spacer()
    }
  }

  func poemList(poems _: [Poem]) -> some View {
    ScrollViewReader { proxy in
      GeometryReader { geo in
        List {
          toolBar()
            .listRowSeparator(.hidden, edges: .top)
          PoemListView(
            poem: poemsViewStore.filteredPoems,
            useSectionHeader: true
          )
        }
        .listStyle(.plain)
        .overlay(alignment: .trailing) {
          PoemIndexView(
            poems: poemsViewStore.filteredPoems, containerHeight: .init(get: {
              return geo.size.height

            }, set: { _ in

            }), scrollProxy: proxy
          )
          .fixedSize(horizontal: true, vertical: true)
          .offset(x: -20, y: 0)
        }
      }
    }
  }

  @ViewBuilder
  private func searchAndContent(poems: [Poem]) -> some View {
    if let searchedPoems = poemsViewStore.searchedPoems {
      SearchPoemView(matchedPoems: searchedPoems)
    }
    else {
      poemList(poems: poems)
    }
  }

  @ViewBuilder
  var content: some View {
    searchAndContent(poems: allPoems)
      .searchable(
        text: $poemsViewStore.searchedText,
        placement: .navigationBarDrawer(displayMode: .always),
        prompt: PredefinedString.searchPoem
      )
  }

  var body: some View {
    content
      .onChange(of: allPoems, initial: true) { _, newValue in
        poemsViewStore.update(poems: newValue)
      }
  }

  private var allPoems: [Poem] {
    cdPoems.map { Poem($0) }.sorted { $0.title.chineseCompare($1.title) == .orderedAscending }
  }
}

struct PoemsView_Previews: PreviewProvider {
  static var previews: some View {
    PoemsView()
  }
}
