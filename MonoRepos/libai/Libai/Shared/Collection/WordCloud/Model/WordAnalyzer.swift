//
//  WordAnalyzer.swift
//  Libai (iOS)
//
//  Created by huahuahu on 2022/4/22.
//

import Combine
import Foundation

struct WordEntry: Encodable, Equatable {
  let word: String
  let count: Int
}

final class WordAnalyzer: ObservableObject {
  @Published private(set) var wordList: [WordEntry]?
//    private var rawText: [String] = []
  private var currentTask: Task<Void, Never>?

  func updateRawText(_ rawText: [String], maxCount: Int) {
    hLog("new content to analyse", scenerio: .wordCloud)
    currentTask?.cancel()
    currentTask = Task {
      let tokens = rawText.flatMap { sentence -> [String] in
        let result = sentence.getWords(of: [.noun])
        let set: Set<String> = result.reduce(into: []) { partialResult, string in
          partialResult.insert(string)
        }
        return set.shuffled()
      }
      let tokenMap: [String: Int] = tokens.reduce(into: [:]) { partialResult, token in
        if let count = partialResult[token] {
          partialResult[token] = count + 1
        }
        else {
          partialResult[token] = 1
        }
      }
      let entries = tokenMap.enumerated().map {
        WordEntry(word: $0.element.key, count: $0.element.value)
      }
      .sorted { $0.count > $1.count
      }
      .prefix(30)

      if let max = entries.map(\.count).max() {
        let newEntries = entries.map { entry -> WordEntry in
          let newCount = entry.count * maxCount / max
          return WordEntry(word: entry.word, count: newCount)
        }
//          try? await Task.sleep(nanoseconds: 2.inNanoSeconds)
        if Task.isCancelled {
          return
        }
        await MainActor.run {
          wordList = Array(newEntries)
        }
      }
      else {
        if Task.isCancelled {
          return
        }
        await MainActor.run {
          wordList = []
        }
      }
    }
  }
}
