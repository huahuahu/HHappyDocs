#if os(iOS)
import Foundation

/// Calendar-day decisions are separate from the system's live minute/hour formatting.
nonisolated struct MomentWidgetDate {
  enum Presentation: Equatable {
    case relativeTime
    case relativeDay(Int)
    case calendarDate(includesYear: Bool)
  }

  let timestamp: Date
  let referenceDate: Date
  let calendar: Calendar
  let locale: Locale

  var presentation: Presentation {
    let days = calendar.dateComponents(
      [.day], from: calendar.startOfDay(for: timestamp), to: calendar.startOfDay(for: referenceDate)
    ).day ?? 0
    if timestamp <= referenceDate {
      if days == 0 {
        return .relativeTime
      }
      if (1 ... 6).contains(days) {
        return .relativeDay(days)
      }
    }
    return .calendarDate(includesYear: !calendar.isDate(timestamp, equalTo: referenceDate, toGranularity: .year))
  }

  var relativeTimeStyle: Date.AnchoredRelativeFormatStyle {
    Date.AnchoredRelativeFormatStyle(
      anchor: timestamp, allowedFields: [.minute, .hour], presentation: .named,
      unitsStyle: .abbreviated, locale: locale, calendar: calendar
    )
  }

  var formatted: String {
    switch presentation {
    case .relativeTime:
      relativeTimeStyle.format(referenceDate)
    case let .relativeDay(days):
      relativeDay(days)
    case let .calendarDate(includesYear):
      timestamp.formatted(includesYear ? calendarDateStyle.year() : calendarDateStyle)
    }
  }

  private var calendarDateStyle: Date.FormatStyle {
    Date.FormatStyle(locale: locale, calendar: calendar, timeZone: calendar.timeZone)
      .month(.abbreviated).day()
  }

  private func relativeDay(_ days: Int) -> String {
    let formatter = RelativeDateTimeFormatter()
    formatter.locale = locale
    formatter.calendar = calendar
    formatter.dateTimeStyle = days <= 2 ? .named : .numeric
    formatter.unitsStyle = .abbreviated
    return formatter.localizedString(from: DateComponents(day: -days))
  }
}
#endif
