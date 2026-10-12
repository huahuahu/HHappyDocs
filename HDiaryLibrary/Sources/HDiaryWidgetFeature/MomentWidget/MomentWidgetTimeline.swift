#if os(iOS)
  import Foundation
  import WidgetKit

  enum MomentWidgetTimeline {
    static func make(
      summary: MomentWidgetSummary, now: Date, calendar: Calendar
    ) -> Timeline<MomentEntry> {
      // Minutes and hours update through TimeDataSource. Preload a week of local
      // midnights so day/year labels can advance even if the next reload is delayed.
      let midnights = (1 ... 7).compactMap {
        calendar.date(byAdding: .day, value: $0, to: calendar.startOfDay(for: now))
      }
      let end = midnights.last ?? now.addingTimeInterval(7 * 86_400)
      // Only archive records that can appear in the widget, rather than duplicating
      // the entire history in every future entry.
      let visibleSummary = MomentWidgetSummary(
        participant: summary.participant, moments: Array(summary.moments.prefix(MomentWidgetSummary.maximumMomentCount))
      )
      let futureMoments = visibleSummary.moments.map(\.timeStamp).filter { $0 > now && $0 < end }
      let dates = Set([now] + midnights + futureMoments).sorted()
      return Timeline(
        entries: dates.map { MomentEntry(date: $0, summary: visibleSummary) },
        policy: .after(midnights.first ?? now.addingTimeInterval(86_400))
      )
    }
  }
#endif
