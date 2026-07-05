//
//  MomentGrouperTests.swift
//
//
//  Created by tigerguo on 2023/11/7.
//
#if os(iOS)

  @testable import HDiaryModel
  import HFoundation

  import XCTest

  class MomentGrouperTests: XCTestCase {
    func test_now_5th_of_month() async throws {
      let calendar = Calendar(identifier: .gregorian)
      let dateComponent = DateComponents(calendar: calendar, year: 2023, month: 11, day: 5, hour: 13)

      let relativeDate = try XCTUnwrap(dateComponent.date)

      // future events
      let futureEvents: [Event] = [
        Event(timestamp: DateComponents(calendar: calendar, year: 2024, month: 11, day: 7, hour: 1).date.unsafelyUnwrapped),
        Event(timestamp: DateComponents(calendar: calendar, year: 2023, month: 11, day: 7, hour: 1).date.unsafelyUnwrapped),
        Event(timestamp: DateComponents(calendar: calendar, year: 2023, month: 11, day: 6, hour: 1).date.unsafelyUnwrapped),
      ]

      let todayEvents: [Event] = [
        Event(timestamp: DateComponents(calendar: calendar, year: 2023, month: 11, day: 5, hour: 14).date.unsafelyUnwrapped),
        Event(timestamp: DateComponents(calendar: calendar, year: 2023, month: 11, day: 5, hour: 3).date.unsafelyUnwrapped),
        Event(timestamp: DateComponents(calendar: calendar, year: 2023, month: 11, day: 5, hour: 1).date.unsafelyUnwrapped),
      ]

      let yesterdayEvents: [Event] = [
        Event(timestamp: DateComponents(calendar: calendar, year: 2023, month: 11, day: 4, hour: 23).date.unsafelyUnwrapped),
        Event(timestamp: DateComponents(calendar: calendar, year: 2023, month: 11, day: 4, hour: 16).date.unsafelyUnwrapped),
        Event(timestamp: DateComponents(calendar: calendar, year: 2023, month: 11, day: 4, hour: 3).date.unsafelyUnwrapped),
      ]

      let recent7DayEvents: [Event] = [
        Event(timestamp: DateComponents(calendar: calendar, year: 2023, month: 11, day: 1, hour: 13).date.unsafelyUnwrapped),
        Event(timestamp: DateComponents(calendar: calendar, year: 2023, month: 10, day: 30, hour: 1).date.unsafelyUnwrapped),
      ]

      let octEvents: [Event] = [
        Event(timestamp: DateComponents(calendar: calendar, year: 2023, month: 10, day: 29, hour: 23).date.unsafelyUnwrapped),
        Event(timestamp: DateComponents(calendar: calendar, year: 2023, month: 10, day: 20, hour: 1).date.unsafelyUnwrapped),
      ]

      let year23Events: [Event] = [
        Event(timestamp: DateComponents(calendar: calendar, year: 2023, month: 1, day: 29, hour: 23).date.unsafelyUnwrapped),
        Event(timestamp: DateComponents(calendar: calendar, year: 2023, month: 1, day: 1, hour: 23).date.unsafelyUnwrapped),
      ]

      let year22Events: [Event] = [
        Event(timestamp: DateComponents(calendar: calendar, year: 2022, month: 12, day: 31, hour: 23).date.unsafelyUnwrapped),
        Event(timestamp: DateComponents(calendar: calendar, year: 2022, month: 1, day: 1, hour: 23).date.unsafelyUnwrapped),
      ]

      let grouper = InstanceGrouper<Event>()
      let allEvents = [futureEvents, todayEvents, yesterdayEvents, recent7DayEvents, octEvents, year22Events, year23Events].flatMap { $0 }.shuffled()

      // When
      let groups = grouper.group(allEvents, relative: relativeDate)

      // Then
      XCTAssertEqual(groups.count, 7)

      XCTAssertEqual(groups[0].instances, futureEvents)
      XCTAssertEqual(groups[0].identifier, .future)

      XCTAssertEqual(groups[1].instances, todayEvents)
      XCTAssertEqual(groups[1].identifier, .today)

      XCTAssertEqual(groups[2].instances, yesterdayEvents)
      XCTAssertEqual(groups[2].identifier, .yesterday)

      XCTAssertEqual(groups[3].instances, recent7DayEvents)
      XCTAssertEqual(groups[3].identifier, .recent7Days)

      XCTAssertEqual(groups[4].instances, octEvents)
      if case .thisYear(let date) = groups[4].identifier {
        let component = calendar.dateComponents([.month, .year], from: date)
        XCTAssertEqual(component.month, 10)
        XCTAssertEqual(component.year, 2023)
      }
      else {
        XCTFail("group[4] should be oct")
      }

      XCTAssertEqual(groups[5].instances, year23Events)
      if case .thisYear(let date) = groups[5].identifier {
        let component = calendar.dateComponents([.year], from: date)
        XCTAssertNotEqual(component.month, 10)
        XCTAssertEqual(component.year, 2023)
      }
      else {
        XCTFail("group[5] should be 2023 year but not oct")
      }

      XCTAssertEqual(groups[6].instances, year22Events)
      if case .previousYear(let date) = groups[6].identifier {
        let component = calendar.dateComponents([.year], from: date)

        XCTAssertEqual(component.year, 2022)
      }
      else {
        XCTFail("group[6] should be 2022")
      }
    }

    func test_now_8th_of_month() async throws {
      let calendar = Calendar(identifier: .gregorian)
      let dateComponent = DateComponents(calendar: calendar, year: 2023, month: 11, day: 8, hour: 13)

      let relativeDate = try XCTUnwrap(dateComponent.date)

      let todayEvents: [Event] = [
        Event(timestamp: DateComponents(calendar: calendar, year: 2023, month: 11, day: 8, hour: 14).date.unsafelyUnwrapped),
        Event(timestamp: DateComponents(calendar: calendar, year: 2023, month: 11, day: 8, hour: 3).date.unsafelyUnwrapped),
        Event(timestamp: DateComponents(calendar: calendar, year: 2023, month: 11, day: 8, hour: 1).date.unsafelyUnwrapped),
      ]

      let recent7DayEvents: [Event] = [
        Event(timestamp: DateComponents(calendar: calendar, year: 2023, month: 11, day: 5, hour: 13).date.unsafelyUnwrapped),
        Event(timestamp: DateComponents(calendar: calendar, year: 2023, month: 11, day: 2, hour: 1).date.unsafelyUnwrapped),
      ]

      let novEvents: [Event] = [
        Event(timestamp: DateComponents(calendar: calendar, year: 2023, month: 11, day: 1, hour: 13).date.unsafelyUnwrapped),
        Event(timestamp: DateComponents(calendar: calendar, year: 2023, month: 11, day: 1, hour: 1).date.unsafelyUnwrapped),
      ]

      let octEvents: [Event] = [
        Event(timestamp: DateComponents(calendar: calendar, year: 2023, month: 10, day: 29, hour: 23).date.unsafelyUnwrapped),
        Event(timestamp: DateComponents(calendar: calendar, year: 2023, month: 10, day: 20, hour: 1).date.unsafelyUnwrapped),
      ]

      let grouper = InstanceGrouper<Event>()
      let allEvents = [todayEvents, recent7DayEvents, novEvents, octEvents].flatMap { $0 }.shuffled()

      // When
      let groups = grouper.group(allEvents, relative: relativeDate)

      // Then
      XCTAssertEqual(groups.count, 4)

      XCTAssertEqual(groups[0].instances, todayEvents)
      XCTAssertEqual(groups[0].identifier, .today)

      XCTAssertEqual(groups[1].instances, recent7DayEvents)
      XCTAssertEqual(groups[1].identifier, .recent7Days)

      XCTAssertEqual(groups[2].instances, novEvents)
      if case .thisYear(let date) = groups[2].identifier {
        let component = calendar.dateComponents([.month, .year], from: date)
        XCTAssertEqual(component.month, 11)
        XCTAssertEqual(component.year, 2023)
      }
      else {
        XCTFail("group[2] should be nov")
      }

      XCTAssertEqual(groups[3].instances, octEvents)
      if case .thisYear(let date) = groups[3].identifier {
        let component = calendar.dateComponents([.month, .year], from: date)
        XCTAssertEqual(component.month, 10)
        XCTAssertEqual(component.year, 2023)
      }
      else {
        XCTFail("group[3] should be oct")
      }
    }

    func test_now_2_of_January() async throws {
      let calendar = Calendar(identifier: .gregorian)
      let dateComponent = DateComponents(calendar: calendar, year: 2025, month: 1, day: 2, hour: 13)

      let relativeDate = try XCTUnwrap(dateComponent.date)

      // future events
      let futureEvents: [Event] = [
        Event(timestamp: DateComponents(calendar: calendar, year: 2025, month: 1, day: 8, hour: 1).date.unsafelyUnwrapped),
        Event(timestamp: DateComponents(calendar: calendar, year: 2025, month: 1, day: 7, hour: 1).date.unsafelyUnwrapped),
        Event(timestamp: DateComponents(calendar: calendar, year: 2025, month: 1, day: 6, hour: 1).date.unsafelyUnwrapped),
      ]

      let todayEvents: [Event] = [
        Event(timestamp: DateComponents(calendar: calendar, year: 2025, month: 1, day: 2, hour: 14).date.unsafelyUnwrapped),
        Event(timestamp: DateComponents(calendar: calendar, year: 2025, month: 1, day: 2, hour: 3).date.unsafelyUnwrapped),
        Event(timestamp: DateComponents(calendar: calendar, year: 2025, month: 1, day: 2, hour: 1).date.unsafelyUnwrapped),
      ]

      let yesterdayEvents: [Event] = [
        Event(timestamp: DateComponents(calendar: calendar, year: 2025, month: 1, day: 1, hour: 23).date.unsafelyUnwrapped),
        Event(timestamp: DateComponents(calendar: calendar, year: 2025, month: 1, day: 1, hour: 16).date.unsafelyUnwrapped),
        Event(timestamp: DateComponents(calendar: calendar, year: 2025, month: 1, day: 1, hour: 3).date.unsafelyUnwrapped),
      ]

      let recent7DayEvents: [Event] = [
        Event(timestamp: DateComponents(calendar: calendar, year: 2024, month: 12, day: 31, hour: 13).date.unsafelyUnwrapped),
        Event(timestamp: DateComponents(calendar: calendar, year: 2024, month: 12, day: 30, hour: 1).date.unsafelyUnwrapped),
      ]

      let year24Events: [Event] = [
        Event(timestamp: DateComponents(calendar: calendar, year: 2024, month: 1, day: 29, hour: 23).date.unsafelyUnwrapped),
        Event(timestamp: DateComponents(calendar: calendar, year: 2024, month: 1, day: 1, hour: 23).date.unsafelyUnwrapped),
      ]

      let year22Events: [Event] = [
        Event(timestamp: DateComponents(calendar: calendar, year: 2022, month: 12, day: 31, hour: 23).date.unsafelyUnwrapped),
        Event(timestamp: DateComponents(calendar: calendar, year: 2022, month: 1, day: 1, hour: 23).date.unsafelyUnwrapped),
      ]

      let grouper = InstanceGrouper<Event>()
      let allEvents = [futureEvents, todayEvents, yesterdayEvents, recent7DayEvents, year24Events, year22Events].flatMap { $0 }.shuffled()

      // When
      let groups = grouper.group(allEvents, relative: relativeDate)

      // Then
      XCTAssertEqual(groups.count, 6)

      XCTAssertEqual(groups[0].instances, futureEvents)
      XCTAssertEqual(groups[0].identifier, .future)

      XCTAssertEqual(groups[1].instances, todayEvents)
      XCTAssertEqual(groups[1].identifier, .today)

      XCTAssertEqual(groups[2].instances, yesterdayEvents)
      XCTAssertEqual(groups[2].identifier, .yesterday)

      XCTAssertEqual(groups[3].instances, recent7DayEvents)
      XCTAssertEqual(groups[3].identifier, .recent7Days)

      XCTAssertEqual(groups[4].instances, year24Events)
      if case .previousYear(year: let date) = groups[4].identifier {
        let component = calendar.dateComponents([.month, .year], from: date)

        XCTAssertEqual(component.year, 2024)
      }
      else {
        XCTFail("group[4] should be 2024")
      }

      XCTAssertEqual(groups[5].instances, year22Events)
      if case .previousYear(year: let date) = groups[5].identifier {
        let component = calendar.dateComponents([.year], from: date)
        XCTAssertEqual(component.year, 2022)
      }
      else {
        XCTFail("group[5] should be 2022 year")
      }
    }

    func test_now_8_of_January() async throws {
      let calendar = Calendar(identifier: .gregorian)
      let dateComponent = DateComponents(calendar: calendar, year: 2025, month: 1, day: 8, hour: 13)

      let relativeDate = try XCTUnwrap(dateComponent.date)

      // future events
      let futureEvents: [Event] = [
        Event(timestamp: DateComponents(calendar: calendar, year: 2025, month: 1, day: 11, hour: 1).date.unsafelyUnwrapped),
        Event(timestamp: DateComponents(calendar: calendar, year: 2025, month: 1, day: 10, hour: 1).date.unsafelyUnwrapped),
        Event(timestamp: DateComponents(calendar: calendar, year: 2025, month: 1, day: 9, hour: 1).date.unsafelyUnwrapped),
      ]

      let todayEvents: [Event] = [
        Event(timestamp: DateComponents(calendar: calendar, year: 2025, month: 1, day: 8, hour: 14).date.unsafelyUnwrapped),
        Event(timestamp: DateComponents(calendar: calendar, year: 2025, month: 1, day: 8, hour: 3).date.unsafelyUnwrapped),
        Event(timestamp: DateComponents(calendar: calendar, year: 2025, month: 1, day: 8, hour: 1).date.unsafelyUnwrapped),
      ]

      let yesterdayEvents: [Event] = [
        Event(timestamp: DateComponents(calendar: calendar, year: 2025, month: 1, day: 7, hour: 23).date.unsafelyUnwrapped),
        Event(timestamp: DateComponents(calendar: calendar, year: 2025, month: 1, day: 7, hour: 16).date.unsafelyUnwrapped),
        Event(timestamp: DateComponents(calendar: calendar, year: 2025, month: 1, day: 7, hour: 3).date.unsafelyUnwrapped),
      ]

      let recent7DayEvents: [Event] = [
        Event(timestamp: DateComponents(calendar: calendar, year: 2025, month: 1, day: 6, hour: 13).date.unsafelyUnwrapped),
        Event(timestamp: DateComponents(calendar: calendar, year: 2025, month: 1, day: 4, hour: 1).date.unsafelyUnwrapped),
      ]

      let year24Events: [Event] = [
        Event(timestamp: DateComponents(calendar: calendar, year: 2024, month: 1, day: 29, hour: 23).date.unsafelyUnwrapped),
        Event(timestamp: DateComponents(calendar: calendar, year: 2024, month: 1, day: 1, hour: 23).date.unsafelyUnwrapped),
      ]

      let janEvents: [Event] = [
        Event(timestamp: DateComponents(calendar: calendar, year: 2025, month: 1, day: 1, hour: 23).date.unsafelyUnwrapped),
        Event(timestamp: DateComponents(calendar: calendar, year: 2025, month: 1, day: 1, hour: 2).date.unsafelyUnwrapped),
      ]

      let grouper = InstanceGrouper<Event>()
      let allEvents = [futureEvents, todayEvents, yesterdayEvents, recent7DayEvents, year24Events, janEvents].flatMap { $0 }.shuffled()

      // When
      let groups = grouper.group(allEvents, relative: relativeDate)

      // Then
      XCTAssertEqual(groups.count, 6)

      XCTAssertEqual(groups[0].instances, futureEvents)
      XCTAssertEqual(groups[0].identifier, .future)

      XCTAssertEqual(groups[1].instances, todayEvents)
      XCTAssertEqual(groups[1].identifier, .today)

      XCTAssertEqual(groups[2].instances, yesterdayEvents)
      XCTAssertEqual(groups[2].identifier, .yesterday)

      XCTAssertEqual(groups[3].instances, recent7DayEvents)
      XCTAssertEqual(groups[3].identifier, .recent7Days)

      XCTAssertEqual(groups[4].instances, janEvents)
      if case .thisYear(let date) = groups[4].identifier {
        let component = calendar.dateComponents([.month, .year], from: date)
        XCTAssertEqual(component.month, 1)
        XCTAssertEqual(component.year, 2025)
      }
      else {
        XCTFail("group[4] should be 2024")
      }

      XCTAssertEqual(groups[5].instances, year24Events)
      if case .previousYear(year: let date) = groups[5].identifier {
        let component = calendar.dateComponents([.year], from: date)
        XCTAssertEqual(component.year, 2024)
      }
      else {
        XCTFail("group[5] should be 2022 year")
      }
    }
  }

  private struct Event: DateGrouppable, Equatable {
    let timestamp: Date
    let uuid = UUID()
  }

#endif
