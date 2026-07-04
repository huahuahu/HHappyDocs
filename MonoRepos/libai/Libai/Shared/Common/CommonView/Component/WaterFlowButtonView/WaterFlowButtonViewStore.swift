//
//  WaterFlowButtonViewStore.swift
//  Libai (iOS)
//
//  Created by tigerguo on 2022/4/28.
//

import CoreGraphics
import Foundation

final class WaterFlowButtonStore: ObservableObject {
  struct CacheKey: Hashable {
    let texts: [String]
    let config: WaterFlowButtonView.Config
  }

  @Published var result: [[WaterFlowButtonView.Item]]?

  private var cache = [CacheKey: [Double]]()
  private(set) var textWidthMap = [String: Double]()
  private var currentTask: Task<Void, Never>?

  init() {}

  func updateRawTexts(items: [WaterFlowButtonView.Item], config: WaterFlowButtonView.Config) {
    hLog("texts: \(items.map(\.text)), width \(config.containerWidth)", scenerio: .default)
    currentTask?.cancel()
    currentTask = Task {
      let cacheKey = CacheKey(texts: items.map(\.text), config: config)
      if let widths = cache[cacheKey] {
        let result = getResult(items: items, widths: widths, config: config)

        await MainActor.run(body: {
          hLog("result is \(result)", scenerio: .default)
          self.result = result
        })
        return
      }
      cache.removeAll()
      cache[cacheKey] = []
      textWidthMap.removeAll()

      let widths = getWidth(items: items, config: config)
      cache[cacheKey] = widths
      for index in (0 ..< widths.count) {
        textWidthMap[items[index].text] = widths[index]
      }

      if Task.isCancelled {
        return
      }
      let result = getResult(items: items, widths: widths, config: config)
      await MainActor.run(body: {
        self.result = result
      })
    }
  }

  private func getWidth(items: [WaterFlowButtonView.Item], config: WaterFlowButtonView.Config) -> [Double] {
    items.map(\.text).map { $0.rectUsing(config.font).width }.map { ceil($0 * 1.0) }
  }

  private func getResult(items: [WaterFlowButtonView.Item], widths: [Double], config: WaterFlowButtonView.Config) -> [[WaterFlowButtonView.Item]] {
    hAssertion(items.count == widths.count, "items length \(items.count) !=  widths length \(widths.count)")
    var result = [[WaterFlowButtonView.Item]]()
    var currentRowItems = [WaterFlowButtonView.Item]()
    var currentPosition = -config.margin
    for index in 0 ..< items.count {
      let currentItem = items[index]
      let currentWidth = widths[index]
      currentPosition += config.margin + currentWidth + config.padding * 2
      if currentPosition > config.containerWidth {
        result.append(currentRowItems)
        currentRowItems = [currentItem]
        currentPosition = currentWidth + config.padding * 2
      }
      else {
        currentRowItems.append(currentItem)
      }
    }
    if !currentRowItems.isEmpty {
      result.append(currentRowItems)
    }

    return result
  }
}
