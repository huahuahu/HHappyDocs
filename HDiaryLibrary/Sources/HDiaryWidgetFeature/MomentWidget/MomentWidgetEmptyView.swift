#if os(iOS)
  import SwiftUI
  import WidgetKit

  struct MomentWidgetEmptyView: View {
    var body: some View {
      VStack(alignment: .leading, spacing: 6) {
        Text("moment.empty.label", tableName: "Intents", bundle: .main)
          .font(.headline)
          .foregroundStyle(.primary)
        Text("widget.moment.empty.description", tableName: "Intents", bundle: .main)
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
  }
#endif
