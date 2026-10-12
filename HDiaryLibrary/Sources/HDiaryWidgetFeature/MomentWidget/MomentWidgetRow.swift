#if os(iOS)
  import SwiftUI
  import WidgetKit

  struct MomentWidgetRow: View {
    let moment: MomentWidgetSummary.Moment
    let family: WidgetFamily
    let referenceDate: Date
    var titleLineLimit = 2

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
      let layout = family == .systemMedium && !dynamicTypeSize.isAccessibilitySize
        ? AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 12))
        : AnyLayout(VStackLayout(alignment: .leading, spacing: 3))
      layout {
        Text(moment.title)
          .font(.subheadline)
          .fontWeight(.medium)
          .foregroundStyle(.primary)
          .lineLimit(titleLineLimit)
          .multilineTextAlignment(.leading)
          .frame(maxWidth: .infinity, alignment: .leading)
        MomentWidgetDateText(
          timestamp: moment.timeStamp, referenceDate: referenceDate,
          alignment: family == .systemMedium && !dynamicTypeSize.isAccessibilitySize ? .trailing : .leading
        )
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(1)
          .fixedSize(horizontal: true, vertical: false)
      }
      .accessibilityElement(children: .combine)
    }
  }
#endif
