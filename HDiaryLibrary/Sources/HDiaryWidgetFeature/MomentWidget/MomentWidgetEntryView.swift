#if os(iOS)
  import SwiftUI
  import WidgetKit

  struct MomentWidgetEntryView: View {
    let entry: MomentEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
      MomentWidgetContentView(entry: entry, family: family)
        .containerBackground(.background, for: .widget)
    }
  }
#endif
