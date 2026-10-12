#if DEBUG
  @testable import HDiaryWidgetFeature
  import HDiaryWidgetIntents
  import SwiftUI
  import WidgetKit

  /// Render components in a real WidgetKit host; explicit families match each Preview's size.
  struct MomentWidgetComponentPreview: Widget {
    enum Component {
      case header, empty
      case content(WidgetFamily), moments(WidgetFamily), row(WidgetFamily)
    }

    private var component = Component.header

    init() {}

    init(_ component: Component) {
      self.component = component
    }

    var body: some WidgetConfiguration {
      AppIntentConfiguration(
        kind: "MomentWidgetComponentPreview",
        intent: MomentWidgetIntent.self,
        provider: MomentTimeLineProvider()
      ) { entry in
        Group {
          switch component {
          case let .content(family):
            MomentWidgetContentView(entry: entry, family: family)
          case .header:
            MomentWidgetHeader(participant: entry.summary.participant)
          case let .moments(family):
            MomentWidgetMomentsView(moments: entry.summary.moments, family: family, referenceDate: entry.date)
          case let .row(family):
            if let moment = entry.summary.moments.first {
              MomentWidgetRow(moment: moment, family: family, referenceDate: entry.date)
            }
          case .empty:
            MomentWidgetEmptyView()
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .environment(\.widgetDatesUseLiveTime, false)
        .containerBackground(.background, for: .widget)
      }
      .supportedFamilies([.systemMedium, .systemLarge])
    }
  }
#endif
