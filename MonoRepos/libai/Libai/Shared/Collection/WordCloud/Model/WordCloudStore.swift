//
//  WordCloudStore.swift
//  Libai (iOS)
//
//  Created by huahuahu on 2022/4/22.
//

import Combine
import Foundation

class WordCloudStore: ObservableObject {
  let wordAnalyzer = WordAnalyzer()
  private var anyCancellables = [AnyCancellable]()
  let wordCloudModel = WordCloudModel()

  @Published var poems = [Poem]()
  @Published var isShowingWordCloud = false
  @Published var filterModel = PoemFilterModel(genreOptions: [], lifeStage: [])

  deinit {
    hLog("store deinit", scenerio: .wordCloud)
  }

  init() {
    hLog("store init", scenerio: .wordCloud)
    wordCloudModel.isShowingUpdateCallBack = { [weak self] isShowingPicture in
      self?.isShowingWordCloud = isShowingPicture
    }

    $poems.removeDuplicates()
      .combineLatest($filterModel.removeDuplicates(), wordCloudModel.$loadFinish)
      .sink { [weak self] poems, filterModel, loadFinish in
        guard let self = self else { return }
        guard loadFinish else { return }
        self.wordCloudModel.setIsUpdating()
        let filteredPoems = self.applyFilter(filterModel, poems: poems)
        let webViewSize = self.wordCloudModel.webView.bounds.size
        hLog(" webviewSize \(webViewSize)", scenerio: .wordCloud)
        // Get max font size for words
        let maxCount = 100.0 * (webViewSize.height * webViewSize.width / 375.0 / 583.0).squareRoot()
        self.wordAnalyzer.updateRawText(filteredPoems.map(\.content), maxCount: Int(maxCount))
      }
      .store(in: &anyCancellables)

    wordAnalyzer.$wordList
      .compactMap { $0 }
      .removeDuplicates()
      .sink { [weak self] wordEntries in
        guard let self = self else { return }
        try? self.wordCloudModel.uploadEntry(wordEntries)
        hLog("word list count \(wordEntries.count)", scenerio: .wordCloud)
      }
      .store(in: &anyCancellables)
  }

  private func applyFilter(_ filterModel: PoemFilterModel, poems: [Poem]) -> [Poem] {
    hLog(" filterModel \(filterModel)", scenerio: .wordCloud)
    return poems
      .filter { poem in
        guard let genre = poem.genre else {
          return true
        }
        let genreOptions = filterModel.genreOptions
        if genreOptions.isEmpty {
          return true
        }
        return filterModel.genreOptions
          .map(\.rawValue)
          .contains(genre)
      }
      .filter { poem in
        if filterModel.lifeStage.isEmpty {
          return true
        }
        let lifeStages = Set(filterModel.lifeStage.map(\.rawValue))
        let allTags = Set(poem.tags)
        return !lifeStages.intersection(allTags).isEmpty
      }
  }

  func triggerNewDraw() {
    wordCloudModel.triggerNewDraw()
  }
}
