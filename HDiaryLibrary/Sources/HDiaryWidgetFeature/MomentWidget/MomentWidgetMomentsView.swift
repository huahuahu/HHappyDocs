#if os(iOS)
  import SwiftUI
  import WidgetKit

  struct MomentWidgetMomentsView: View {
    let moments: [MomentWidgetSummary.Moment]
    let family: WidgetFamily
    let referenceDate: Date

    var body: some View {
      let maximumCount = min(MomentWidgetSummary.maximumMomentCount, moments.count)
      if maximumCount > 0 {
        ViewThatFits(in: .vertical) {
          // Each candidate measures its complete rows. Reduce the number of rows
          // before allowing the system to compress or clip their text.
          ForEach((1 ... maximumCount).reversed(), id: \.self) { count in
            VStack(alignment: .leading, spacing: family == .systemMedium ? 6 : 8) {
              ForEach(moments.prefix(count)) { moment in
                MomentWidgetRow(moment: moment, family: family, referenceDate: referenceDate)
                if moment.id != moments[count - 1].id {
                  Divider()
                }
              }
            }
            .fixedSize(horizontal: false, vertical: true)
          }
          // The smallest widget can still show a complete row at large text sizes.
          if let moment = moments.first {
            MomentWidgetRow(moment: moment, family: family, referenceDate: referenceDate, titleLineLimit: 1)
          }
        }
      }
    }
  }
#endif
