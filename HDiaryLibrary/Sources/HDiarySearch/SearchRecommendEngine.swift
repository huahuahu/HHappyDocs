//
//  SearchRecommendEngine.swift
//  HDiary
//
//  Created by tigerguo on 2025/4/12.
//
  import Foundation
  import HDiaryModel
  import SwiftData

  actor SearchRecommendEngine {
    private enum Constants {
      static let maxRecommendationCount = 5

      static let ratingWeight = 0.5

      static let recencyWeight = 0.3
      static let timeDecayFactor: TimeInterval = 7 * 24 * 60 * 60 // 7天半衰期

      static let openCountWeight = 0.2
      static let maxOpenCount = 10.0
    }

    let modelContext: ModelContext

    init(modelContainer: ModelContainer) {
      self.modelContext = ModelContext(modelContainer)
    }

    func getRecommendedMomentIDs() async -> [PersistentIdentifier] {
      assert(Thread.isMainThread == false, "This should not be called on the main thread")
      var candidates = Set<Moment>()

      // 1. 获取访问次数最多的5个
      var mostVisitedDescriptor = FetchDescriptor<Moment>(
        sortBy: [SortDescriptor(\Moment.visitCount, order: .reverse)]
      )
      mostVisitedDescriptor.fetchLimit = Constants.maxRecommendationCount
      if let mostVisited = try? modelContext.fetch(mostVisitedDescriptor) {
        candidates.formUnion(mostVisited)
      }

      // 2. 获取最近访问的5个
      var recentlyVisitedDescriptor = FetchDescriptor<Moment>(
        sortBy: [SortDescriptor(\Moment.lastVisitDate, order: .reverse)]
      )
      recentlyVisitedDescriptor.fetchLimit = Constants.maxRecommendationCount
      if let recentlyVisited = try? modelContext.fetch(recentlyVisitedDescriptor) {
        candidates.formUnion(recentlyVisited)
      }

      // 3. 获取评分最高的5个
      var highestRatedDescriptor = FetchDescriptor<Moment>(
        sortBy: [SortDescriptor(\Moment.rating, order: .reverse)]
      )
      highestRatedDescriptor.fetchLimit = Constants.maxRecommendationCount
      if let highestRated = try? modelContext.fetch(highestRatedDescriptor) {
        candidates.formUnion(highestRated)
      }

      struct ScoredMoment {
        let moment: Moment
        let score: Double
      }

      // 4. 对候选集合进行综合排序
      let now = Date()
      let scoredCandidates = candidates.map { moment in
        ScoredMoment(
          moment: moment,
          score: calculateScore(for: moment, currentDate: now)
        )
      }

      // 直接使用预计算的得分进行排序
      return Array(
        scoredCandidates
          .sorted { $0.score > $1.score }
          .map(\.moment)
          .prefix(Constants.maxRecommendationCount)
      ).map(\.persistentModelID)
    }

    private func calculateScore(for moment: Moment, currentDate: Date) -> Double {
      // 访问次数得分 (0-1)
      let visitScore = min(Double(moment.visitCount) / Constants.maxOpenCount, 1.0)

      // 时间衰减得分 (0-1)
      let timeInterval = currentDate.timeIntervalSince(moment.lastVisitDate ?? currentDate)
      let recencyScore = exp(-timeInterval / Constants.timeDecayFactor)

      // 评分得分 (0-1)
      let ratingScore = Double(moment.rating) / 5.0

      // 加权计算总分
      return visitScore * Constants.openCountWeight +
        recencyScore * Constants.recencyWeight +
        ratingScore * Constants.ratingWeight
    }
  }

