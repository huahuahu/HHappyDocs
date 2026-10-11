//
//  MomentWidget.swift
//  HDiaryWidget
//
//  Created by tigerguo on 2023/7/14.
//

#if os(iOS)

  import HDiaryConstants
  import HDiaryWidgetIntents
  import SwiftUI
  import WidgetKit

  struct MomentWidget: Widget {
    let kind: String = HDiaryIntentKind.moment.rawValue

    var body: some WidgetConfiguration {
      AppIntentConfiguration(
        kind: kind,
        intent: MomentWidgetIntent.self,
        provider: MomentTimeLineProvider()
      ) { entry in
        MomentWidgetEntryView(entry: entry)
      }
      .configurationDisplayName(
        LocalizedStringResource(
          "widget.moment.configurationDisplayName",
          defaultValue: "Moments",
          table: "Intents",
          bundle: .main
        )
      )
      .description(
        LocalizedStringResource(
          "widget.moment.description",
          defaultValue: "Show moments for a selected participant",
          table: "Intents",
          bundle: .main
        )
      )
      .supportedFamilies([.systemMedium, .systemLarge])
    }
  }

#endif
