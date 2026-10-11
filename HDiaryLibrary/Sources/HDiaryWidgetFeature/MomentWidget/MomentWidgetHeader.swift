#if os(iOS)
  import HDiaryWidgetIntents
  import SwiftUI
  import WidgetKit

  struct MomentWidgetHeader: View {
    let participant: ParticipantEntity?

    @Environment(\.widgetRenderingMode) private var renderingMode

    var body: some View {
      HStack(spacing: 8) {
        if let participant, participant.id != .null {
          Image(uiImage: participant.avatar)
            .renderingMode(participant.avatar.isSymbolImage ? .template : .original)
            .resizable()
            .widgetAccentedRenderingMode(.desaturated)
            .scaledToFill()
            .frame(width: 24, height: 24)
            .clipShape(.circle)
            .accessibilityHidden(true)
          Text(participant.name)
            .lineLimit(1)
        }
        else {
          Text("widget.moment.configurationDisplayName", tableName: "Intents", bundle: .main)
            .lineLimit(1)
        }
        Spacer(minLength: 8)
        // Keep the icon's dark rays and facial details opaque in accented mode.
        Image(renderingMode == .accented ? "WidgetAppIconAccented" : "WidgetAppIcon", bundle: .main)
          .renderingMode(.original)
          .resizable()
          .widgetAccentedRenderingMode(.accented)
          .scaledToFit()
          .frame(width: 24, height: 24)
          .accessibilityHidden(true)
      }
      .font(.subheadline.bold())
    }
  }
#endif
