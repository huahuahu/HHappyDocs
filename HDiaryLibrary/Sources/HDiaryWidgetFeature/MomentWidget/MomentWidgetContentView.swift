#if os(iOS)
  import SwiftUI
  import WidgetKit

  /// The entry view supplies WidgetKit's read-only family; previews and tests share this layout.
  struct MomentWidgetContentView: View {
    let entry: MomentEntry
    let family: WidgetFamily

    var body: some View {
      VStack(alignment: .leading, spacing: 10) {
        MomentWidgetHeader(participant: entry.summary.participant)
        if entry.summary.moments.isEmpty {
          MomentWidgetEmptyView()
        }
        else {
          MomentWidgetMomentsView(moments: entry.summary.moments, family: family, referenceDate: entry.date)
            .frame(maxHeight: .infinity, alignment: .topLeading)
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
  }
#endif
