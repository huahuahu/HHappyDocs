#if os(iOS)
  import Foundation
  @testable import HDiaryWidgetFeature
  import Testing

  struct MomentWidgetDateTests {
    @Test(arguments: [
      ("2026-10-12T11:59:50Z", "此刻"),
      ("2026-10-12T11:30:00Z", "30分钟前"),
      ("2026-10-12T09:00:00Z", "3小时前"),
      ("2026-10-11T23:59:00Z", "昨天"),
      ("2026-10-10T12:00:00Z", "前天"),
      ("2026-10-09T12:00:00Z", "3天前"),
      ("2026-10-06T00:00:00Z", "6天前"),
      ("2026-10-05T23:59:00Z", "10月5日"),
      ("2025-10-01T12:00:00Z", "2025年10月1日"),
    ])
    func chineseSegments(timestamp: String, expected: String) throws {
      let date = try makeDate(timestamp, now: "2026-10-12T12:00:00Z")
      #expect(date.formatted == expected)
    }

    @Test(arguments: [
      ("en_US", "Oct 1, 2025"),
      ("en_GB", "1 Oct 2025"),
      ("zh_CN", "2025年10月1日"),
    ])
    func datesFollowLocale(locale: String, expected: String) throws {
      let date = try makeDate("2025-10-01T12:00:00Z", now: "2026-10-12T12:00:00Z", locale: locale)
      #expect(date.formatted == expected)
    }

    @Test
    func englishRelativeTimeAndDay() throws {
      #expect(try makeDate("2026-10-12T11:30:00Z", now: "2026-10-12T12:00:00Z", locale: "en_US").formatted == "30 min. ago")
      #expect(try makeDate("2026-10-11T23:59:00Z", now: "2026-10-12T00:01:00Z", locale: "en_US").formatted == "yesterday")
    }

    @Test
    func localMidnightWinsOverElapsedHours() throws {
      let timestamp = "2026-10-12T15:59:00Z"
      let now = "2026-10-12T16:01:00Z"
      let shanghai = try makeDate(timestamp, now: now, timeZone: "Asia/Shanghai")
      let losAngeles = try makeDate(timestamp, now: now, timeZone: "America/Los_Angeles")
      #expect(shanghai.presentation == .relativeDay(1))
      #expect(shanghai.formatted == "昨天")
      #expect(losAngeles.presentation == .relativeTime)
      #expect(losAngeles.formatted == "2分钟前")
    }

    @Test(arguments: [
      ("2026-03-08T08:30:00Z", "2026-03-09T07:10:00Z"),
      ("2026-11-01T07:00:00Z", "2026-11-02T08:10:00Z"),
    ])
    func daylightSavingUsesNaturalDays(timestamp: String, now: String) throws {
      let date = try makeDate(timestamp, now: now, timeZone: "America/Los_Angeles")
      #expect(date.presentation == .relativeDay(1))
    }

    @Test
    func yearBoundaryKeepsRecentDaysRelativeAndAddsYearToOldDates() throws {
      let now = "2027-01-01T00:01:00Z"
      #expect(try makeDate("2026-12-31T23:59:00Z", now: now).formatted == "昨天")
      #expect(try makeDate("2026-12-25T12:00:00Z", now: now).formatted == "2026年12月25日")
    }

    @Test
    func futureRecordUsesActualDateUntilItsTimestamp() throws {
      let future = try makeDate("2026-10-12T13:00:00Z", now: "2026-10-12T12:00:00Z")
      #expect(future.presentation == .calendarDate(includesYear: false))
      #expect(future.formatted == "10月12日")
    }

    @Test
    func userCalendarControlsYearBoundary() throws {
      var calendar = Calendar(identifier: .chinese)
      calendar.timeZone = try #require(TimeZone(identifier: "Asia/Shanghai"))
      let timestamp = try Date("2026-02-09T12:00:00Z", strategy: .iso8601)
      let now = try Date("2026-02-17T12:00:00Z", strategy: .iso8601)
      let date = MomentWidgetDate(timestamp: timestamp, referenceDate: now, calendar: calendar, locale: Locale(identifier: "zh_CN"))
      #expect(date.presentation == .calendarDate(includesYear: true))
    }

    @Test
    func systemStyleSchedulesMinuteAndHourChangesWithoutTimelineReload() throws {
      let date = try makeDate("2026-10-12T11:00:00Z", now: "2026-10-12T11:30:00Z")
      let style = date.relativeTimeStyle
      let next = try #require(style.discreteInput(after: date.referenceDate))
      #expect(next > date.referenceDate)
      #expect(next.timeIntervalSince(date.referenceDate) <= 60)
      #expect(style.format(date.referenceDate) == "30分钟前")
      #expect(style.format(date.timestamp.addingTimeInterval(3600)) == "1小时前")
      #expect(style.format(date.timestamp.addingTimeInterval(7200)) == "2小时前")
    }

    private func makeDate(
      _ timestamp: String, now: String, locale: String = "zh_CN", timeZone: String = "UTC"
    ) throws -> MomentWidgetDate {
      var calendar = Calendar(identifier: .gregorian)
      calendar.timeZone = try #require(TimeZone(identifier: timeZone))
      return MomentWidgetDate(
        timestamp: try Date(timestamp, strategy: .iso8601),
        referenceDate: try Date(now, strategy: .iso8601),
        calendar: calendar, locale: Locale(identifier: locale)
      )
    }
  }
#endif
