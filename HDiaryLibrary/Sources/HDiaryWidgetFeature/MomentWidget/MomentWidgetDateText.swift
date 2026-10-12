#if os(iOS)
  import SwiftUI

  extension EnvironmentValues {
    /// Previews and component snapshots can render the entry's clock deterministically.
    @Entry var widgetDatesUseLiveTime = true
  }

  struct MomentWidgetDateText: View {
    let timestamp: Date
    let referenceDate: Date
    var alignment: Alignment = .leading

    @Environment(\.locale) private var locale
    @Environment(\.calendar) private var calendar
    @Environment(\.timeZone) private var timeZone
    @Environment(\.widgetDatesUseLiveTime) private var usesLiveTime

    var body: some View {
      let date = MomentWidgetDate(
        timestamp: timestamp, referenceDate: referenceDate,
        calendar: localCalendar, locale: locale
      )
      if date.presentation == .relativeTime {
        // Live Text cannot remeasure an archived widget. Reserve the localized
        // minute/hour widths before archiving, without imposing a fixed point width.
        ZStack(alignment: alignment) {
          Text(date.formatted).hidden()
          Text(timestamp.addingTimeInterval(59 * 60), format: date.relativeTimeStyle).hidden()
          Text(timestamp.addingTimeInterval(23 * 3600), format: date.relativeTimeStyle).hidden()
        }
        .overlay(alignment: alignment) {
          if usesLiveTime {
            Text(.currentDate, format: date.relativeTimeStyle)
          }
          else {
            Text(referenceDate, format: date.relativeTimeStyle)
          }
        }
        .multilineTextAlignment(alignment == .trailing ? .trailing : .leading)
        .monospacedDigit()
      }
      else {
        Text(date.formatted)
      }
    }

    private var localCalendar: Calendar {
      var result = calendar
      result.timeZone = timeZone
      return result
    }
  }
#endif
