//
//  FilterModel.swift
//  Libai
//
//  Created by huahuahu on 2022/2/6.
//

import Foundation

struct GenreFilterItem: Identifiable, Comparable {
  static func < (lhs: Self, rhs: Self) -> Bool {
    lhs.genre.chineseCompare(rhs.genre) == .orderedAscending
  }

  init(genre: String, count: Int) {
    self.genre = genre
    self.count = count
  }

  let genre: String
  let count: Int
  var id: String {
    genre
  }
}

struct FilterModel {
  enum Constants {
    static let allGenres = "所有体裁"
  }

  init(poems: [Poem]) {
    self.poems = poems
  }

  let poems: [Poem]
  var allGenres: [GenreFilterItem] {
    var genres = poems
      .compactMap(\.genre)
      .reduce(into: [String: Int]()) { partialResult, genre in
        partialResult[genre] = (partialResult[genre] ?? 0) + 1
      }
      .map { (key: String, value: Int) in
        GenreFilterItem(genre: key, count: value)
      }
      .sorted()

    if !genres.isEmpty {
      let allGenreItem = GenreFilterItem(genre: Constants.allGenres, count: genres.map(\.count).sum())
      genres.insert(allGenreItem, at: 0)
    }
    return genres
  }

  func filteredBy(genre: String? = nil, tag: String? = nil) -> [Poem] {
    var filtered = poems
    if let genre = genre {
      filtered = filtered.filter { $0.genre == genre }
    }
    if let tag = tag {
      filtered = filtered.filter { $0.tags.contains(tag) }
    }
    return filtered
      .sorted { $0.title.chineseCompare($1.title) == .orderedAscending }
  }
}
