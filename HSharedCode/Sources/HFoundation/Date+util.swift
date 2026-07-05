//
//  Date+util.swift
//
//
//  Created by tigerguo on 2024/4/11.
//

import Foundation

public extension Calendar {
  func endOfDay(for date: Date) -> Date? {
    // Start of the next day
    if let startOfNextDay = self.date(byAdding: .day, value: 1, to: self.startOfDay(for: date)) {
      // Subtract 1 second to get the last moment of the current day
      return self.date(byAdding: .second, value: -1, to: startOfNextDay)
    }
    return nil
  }

  func startOfPreviousMonthOrJanuaryFirst(from date: Date = Date()) -> Date? {
    var components = dateComponents([.year, .month], from: date)

    guard let month = components.month, components.year != nil else {
      return nil
    }

    if month == 1 {
      // 当前是1月，返回1月1日 00:00
      components.day = 1
      return self.date(from: components)
    }
    else {
      // 不是1月，返回上一个月的1日 00:00
      components.month = month - 1
      components.day = 1
      return self.date(from: components)
    }
  }
}
