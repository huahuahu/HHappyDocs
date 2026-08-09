#if os(iOS)

  import Foundation
  import HDiaryModel
  import SwiftData

  /// 在独立 actor 中执行主 Store 的有界查询，并转换为可跨 actor 传递的快照源值。
  actor MainStoreWidgetSnapshotSourceReader {
    private let container: ModelContainer

    init(container: ModelContainer) {
      self.container = container
    }

    func read(limit: Int) throws -> WidgetSnapshotSourceValue {
      let context = ModelContext(container)
      context.autosaveEnabled = false

      // Widget 配置需要全部 Participant；先转成纯值，后续不再持有模型对象。
      let participantSources = try context.fetch(FetchDescriptor<Participant>()).map {
        WidgetParticipantSource(uuid: $0.uuid, nickName: $0.nickName, avatarData: $0.avatar)
      }
      let boundedLimit = max(0, limit)
      var momentsByID = [UUID: WidgetMomentSource]()

      if boundedLimit > 0 {
        // 全局查询覆盖“全部参与者”配置，也保留未关联 Participant 的 Moment。
        let activeMomentPredicate = #Predicate<Moment> { !$0.markedAsDelete }
        let globalMoments = try context.fetch(momentDescriptor(
          predicate: activeMomentPredicate,
          limit: boundedLimit
        ))
        merge(globalMoments, into: &momentsByID)

        // SwiftData 不支持单次 groupwise Top-N，因此逐个 Participant 做有界查询。
        for participant in participantSources {
          let participantID = participant.uuid
          let participantMomentPredicate = #Predicate<Moment> { moment in
            !moment.markedAsDelete &&
              (moment.participants?.contains { participant in
                participant.uuid == participantID
              } ?? false)
          }
          let participantMoments = try context.fetch(momentDescriptor(
            predicate: participantMomentPredicate,
            limit: boundedLimit
          ))
          merge(participantMoments, into: &momentsByID)
        }
      }

      return WidgetSnapshotSourceValue(
        participants: participantSources,
        moments: Array(momentsByID.values)
      )
    }

    private func momentDescriptor(
      predicate: Predicate<Moment>,
      limit: Int
    ) -> FetchDescriptor<Moment> {
      var descriptor = FetchDescriptor<Moment>(
        predicate: predicate,
        sortBy: [
          SortDescriptor(\Moment.timestamp, order: .reverse),
          SortDescriptor(\Moment.uuid),
        ]
      )
      descriptor.fetchLimit = limit
      descriptor.relationshipKeyPathsForPrefetching = [\Moment.participants]
      return descriptor
    }

    private func merge(
      _ moments: [Moment],
      into momentsByID: inout [UUID: WidgetMomentSource]
    ) {
      for moment in moments where momentsByID[moment.uuid] == nil {
        momentsByID[moment.uuid] = WidgetMomentSource(
          uuid: moment.uuid,
          timestamp: moment.timestamp,
          title: moment.title,
          participantIDs: (moment.participants ?? []).map(\.uuid),
          isDeleted: moment.markedAsDelete
        )
      }
    }
  }

#endif
