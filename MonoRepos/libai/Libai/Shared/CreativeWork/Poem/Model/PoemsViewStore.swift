//
//  PoemsViewStore.swift
//  Libai
//
//  Created by huahuahu on 2022/5/30.
//

import Combine
import Foundation
import Observation

@MainActor
@Observable
final class PoemsViewStore {
  private var allPoems: [Poem] = []
  private(set) var filteredPoems: [Poem] = []
  private(set) var searchedPoems: [SearchedPoem]?

  var selectedGenre: String?
  var searchedText: String = ""
  private(set) var allGenres = [GenreFilterItem]()

  init() {
    onSearchTextChagne()
    onFilterChange()
  }

  private func onSearchTextChagne() {
    withObservationTracking {
      searchedPoems = PoemSearchEngine().filter(poems: filteredPoems, keyword: searchedText)
    } onChange: {
      Task { [weak self] in
        await self?.onSearchTextChagne()
      }
    }
  }

  private func onFilterChange() {
    withObservationTracking {
      let filterModel = FilterModel(poems: allPoems)
      self.allGenres = filterModel.allGenres
      self.filteredPoems = filterModel.filteredBy(genre: selectedGenre)
    } onChange: {
      Task { [weak self] in
        await self?.onFilterChange()
      }
    }
  }

  func update(poems: [Poem]) {
    self.allPoems = poems
  }
}
