//
//  InstanceGrouper.swift
//
//
//  Created by tigerguo on 2023/11/6.
//

#if os(iOS)

  import Algorithms
  import Foundation

  public protocol DateGrouppable {
    var timestamp: Date { get }
  }

  extension Moment: DateGrouppable {}

  public struct InstanceGroup<T: DateGrouppable>: Identifiable {
    public var id: String {
      identifier.id
    }

    public let identifier: GroupIdentifier
    public let instances: [T]

    public enum GroupIdentifier: Identifiable, Equatable {
      case future
      case today
      case yesterday
      case recent7Days
      case thisYear(month: Date)
      case previousYear(year: Date)
      case ungrouped

      public var id: String {
        switch self {
        case .future:
          return "future"
        case .today:
          return "today"
        case .yesterday:
          return "yesterday"
        case .recent7Days:
          return "recentSevenDay"
        case .thisYear(let month):
          return "this year \(month.formatted(date: .abbreviated, time: .omitted))"
        case .previousYear(let year):
          return "previous year \(year.formatted(date: .abbreviated, time: .omitted))"
        case .ungrouped:
          return "ungrouped"
        }
      }
    }
  }

  public struct InstanceGrouper<T: DateGrouppable> {
    public init() {}

    public func group(_ moments: [T], relative to: Date) -> [InstanceGroup<T>] {
      let sortedMoments = moments.sorted { $0.timestamp > $1.timestamp }
      let calendar = Calendar.current

      let startOfRelativeDate = calendar.startOfDay(for: to)
      let yesterdayStart = calendar.date(byAdding: .day, value: -1, to: startOfRelativeDate)
      let recent7DayStart = calendar.date(byAdding: .day, value: -6, to: startOfRelativeDate)
      let startOfThisYear = calendar.date(from: calendar.dateComponents([.year], from: to))

      let result = sortedMoments.chunked { moment -> InstanceGroup<T>.GroupIdentifier in
        if calendar.isDate(to, inSameDayAs: moment.timestamp) {
          return .today
        }
        else if moment.timestamp > to {
          return .future
        }
        else if moment.timestamp < startOfRelativeDate, let yesterdayStart, moment.timestamp >= yesterdayStart {
          return .yesterday
        }
        else if let yesterdayStart, moment.timestamp < yesterdayStart, let recent7DayStart, moment.timestamp >= recent7DayStart {
          return .recent7Days
        }
        else if let startOfThisYear, moment.timestamp < startOfThisYear {
          return .previousYear(year: calendar.date(from: calendar.dateComponents([.year], from: moment.timestamp)) ?? moment.timestamp)
        }
        else if let recent7DayStart, moment.timestamp < recent7DayStart {
          return .thisYear(month: calendar.date(from: calendar.dateComponents([.year, .month], from: moment.timestamp)) ?? moment.timestamp)
        }
        else {
          return .ungrouped
        }
      }

      return result.map { groupID, moments in
        InstanceGroup(identifier: groupID, instances: Array(moments))
      }
    }
  }

#endif
