#if os(iOS)
  import Foundation
  @testable import HDiaryWidgetFeature
  import Testing
  import WidgetKit

  @MainActor
  struct MomentWidgetTimelineTests {
    @Test
    func midnightsArePreloadedAndNextReloadIsDaily() throws {
      let now = try Date("2026-12-31T15:59:00Z", strategy: .iso8601)
      var calendar = Calendar(identifier: .gregorian)
      calendar.timeZone = try #require(TimeZone(identifier: "Asia/Shanghai"))
      let moment = MomentWidgetSummary.Moment(timeStamp: now, title: "Moment", id: UUID())
      let timeline = MomentWidgetTimeline.make(summary: .init(participant: nil, moments: [moment]), now: now, calendar: calendar)
      #expect(timeline.entries.count == 8)
      #expect(timeline.entries.first?.date == now)
      let midnight = try #require(timeline.entries.dropFirst().first)
      #expect(midnight.date == (try Date("2026-12-31T16:00:00Z", strategy: .iso8601)))
      #expect(timeline.policy == .after(midnight.date))
      for (index, entry) in timeline.entries.dropFirst().enumerated() {
        #expect(entry.date == calendar.startOfDay(for: entry.date))
        let date = MomentWidgetDate(timestamp: moment.timeStamp, referenceDate: entry.date, calendar: calendar, locale: Locale(identifier: "zh_CN"))
        #expect(date.presentation == (index < 6 ? .relativeDay(index + 1) : .calendarDate(includesYear: true)))
        #expect(entry.summary.moments.first?.id == moment.id)
      }
    }

    @Test(arguments: [
      ("2026-03-08T08:00:00Z", 23.0),
      ("2026-11-01T07:00:00Z", 25.0),
    ])
    func midnightScheduleFollowsDST(nowString: String, hours: Double) throws {
      let now = try Date(nowString, strategy: .iso8601)
      var calendar = Calendar(identifier: .gregorian)
      calendar.timeZone = try #require(TimeZone(identifier: "America/Los_Angeles"))
      let timeline = MomentWidgetTimeline.make(summary: .init(participant: nil, moments: []), now: now, calendar: calendar)
      let next = try #require(timeline.entries.dropFirst().first?.date)
      #expect(next.timeIntervalSince(now) == hours * 3600)
    }

    @Test
    func futureTimestampGetsAnEntryAndDuplicatesAreRemoved() throws {
      let now = try Date("2026-10-12T12:00:00Z", strategy: .iso8601)
      let future = now.addingTimeInterval(3600)
      let moments = (0 ..< 2).map { _ in MomentWidgetSummary.Moment(timeStamp: future, title: "Future", id: UUID()) }
      var calendar = Calendar(identifier: .gregorian)
      calendar.timeZone = try #require(TimeZone(identifier: "UTC"))
      let timeline = MomentWidgetTimeline.make(summary: .init(participant: nil, moments: moments), now: now, calendar: calendar)
      #expect(timeline.entries.filter { $0.date == future }.count == 1)
      #expect(timeline.entries.map(\.date) == timeline.entries.map(\.date).sorted())
    }

    @Test
    func timelineOnlyArchivesVisibleMoments() throws {
      let now = try Date("2026-10-12T12:00:00Z", strategy: .iso8601)
      let moments = (0 ..< 100).map { index in
        MomentWidgetSummary.Moment(timeStamp: now.addingTimeInterval(Double(index)), title: "Moment", id: UUID())
      }
      let timeline = MomentWidgetTimeline.make(summary: .init(participant: nil, moments: moments), now: now, calendar: Calendar(identifier: .gregorian))
      #expect(timeline.entries.allSatisfy { $0.summary.moments.count == 8 })
      #expect(timeline.entries.contains { $0.date == moments[8].timeStamp } == false)
    }
  }
#endif
