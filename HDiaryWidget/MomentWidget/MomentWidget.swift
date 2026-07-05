//
//  MomentWidget.swift
//  HDiaryWidget
//
//  Created by tigerguo on 2023/7/14.
//

import HDiaryConstants
import HDiaryModel
import SwiftUI
import WidgetKit

struct MomentWidgetEntryView: View {
  init(entry: MomentEntry) {
    self.entry = entry
  }

  var entry: MomentEntry

  private var avatarSize: CGFloat = 18.0

  @ScaledMetric private var cornerRadius = 10.0
  @ScaledMetric private var participantVerticalPadding = 5.0
  @ScaledMetric private var paddingBetweenTimeAndTitle = 2.0
  @ScaledMetric private var paddingBetweenMoments = 5.0
  @Environment(\.widgetFamily) private var widgetFamily

  var body: some View {
    VStack(spacing: 10) {
      if let participant = entry.summary.participant, participant.id != .null {
        participantView(for: participant)
      }
      momentsView(for: entry.summary.moments)
      Spacer()
    }
    .containerBackground(.regularMaterial, for: .widget)
  }

  private func participantView(for participant: ParticipantEntity) -> some View {
    HStack {
      Image(uiImage: participant.avatar)
        .resizable()
        .aspectRatio(contentMode: .fill)
        .frame(width: avatarSize, height: avatarSize)
      Text(participant.name)
        .font(.subheadline)
        .bold()
      Spacer()
    }
    .padding(.top, participantVerticalPadding)
    .padding(.bottom, participantVerticalPadding)
    .padding(.leading)
    .background(.accent)
    .clipShape(ContainerRelativeShape())
  }

  @ViewBuilder
  private func momentsView(for moments: [MomentWidgetSummary.Moment]) -> some View {
    if moments.isEmpty {
      NoMomentView()
    }
    else {
      let maxCount = min(8, moments.count)
      ViewThatFits(in: .vertical) {
        ForEach((1 ... maxCount).reversed(), id: \.self) { index in
          VStack(alignment: .leading, spacing: paddingBetweenMoments) {
            ForEach(moments.prefix(index)) { moment in
              momentView(for: moment)
                .padding(.vertical, paddingBetweenMoments)
                .padding(.horizontal)
                .background(.accent.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            }
          }
        }
      }
    }
  }

  @ViewBuilder func momentView(for moment: MomentWidgetSummary.Moment) -> some View {
    if widgetFamily == .systemMedium {
      Text(moment.title)
        .foregroundStyle(.primary)
        .font(.subheadline)
        .multilineTextAlignment(.leading)
        .lineLimit(2)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    else {
      VStack(alignment: .leading, spacing: paddingBetweenTimeAndTitle) {
        Text(moment.timeStamp, style: .date)
          .font(.caption)
          .foregroundStyle(.secondary)
        Text(moment.title)
          .foregroundStyle(.primary)
          .font(.subheadline)
          .multilineTextAlignment(.leading)
          .lineLimit(2)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
  }
}

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
    .configurationDisplayName("widget.moment.configurationDisplayName")
    .description("widget.moment.description")
    .supportedFamilies([.systemMedium, .systemLarge])
  }
}

#Preview("one", as: .systemMedium) {
  MomentWidget()
} timeline: {
  MomentEntry(date: .now, summary: MomentWidgetSummary(
    participant: .placeHolder,
    moments: [.demo1]
  ))
}

#Preview("two", as: .systemMedium) {
  MomentWidget()
} timeline: {
  MomentEntry(date: .now, summary: .placeHolder)
}

#Preview("three", as: .systemMedium) {
  MomentWidget()
} timeline: {
  MomentEntry(date: .now, summary: MomentWidgetSummary(
    participant: .placeHolder,
    moments: [.demo1, .demo2, .demo3]
  ))
}

#Preview("three large", as: .systemLarge) {
  MomentWidget()
} timeline: {
  MomentEntry(date: .now, summary: MomentWidgetSummary(
    participant: .placeHolder,
    moments: [.demo1, .demo2, .demo3]
  ))
}

#Preview("empty", as: .systemMedium) {
  MomentWidget()
} timeline: {
  MomentEntry(date: .now, summary: .empty)
}
