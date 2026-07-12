#if os(iOS)

import Foundation
import HDiaryConstants
import SwiftUI

struct LibraryEntryCard: View {
  @ScaledMetric(relativeTo: .body) private var cardPadding: CGFloat = 14
  @ScaledMetric(relativeTo: .body) private var columnSpacing: CGFloat = 8
  @ScaledMetric(relativeTo: .body) private var rowSpacing: CGFloat = 12
  @ScaledMetric(relativeTo: .body) private var cornerRadius: CGFloat = 20
  @ScaledMetric(relativeTo: .body) private var verticalMinimumHeight: CGFloat = 138
  @ScaledMetric(relativeTo: .body) private var horizontalMinimumHeight: CGFloat = 82

  let entry: LibraryEntry
  let summary: LocalizedStringResource
  let contentAxis: Axis

  var body: some View {
    Group {
      if contentAxis == .vertical {
        VStack(alignment: .leading, spacing: columnSpacing) {
          entryIcon
          Text(entry.label)
            .font(.headline)
            .bold()
            .foregroundStyle(.primary)
            .fixedSize(horizontal: false, vertical: true)
          Text(summary)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
          Spacer(minLength: 0)
          HStack {
            Spacer(minLength: 0)
            disclosureIndicator
          }
        }
      }
      else {
        HStack(spacing: rowSpacing) {
          entryIcon
          VStack(alignment: .leading, spacing: columnSpacing / 2) {
            Text(entry.label)
              .font(.headline)
              .bold()
              .foregroundStyle(.primary)
              .fixedSize(horizontal: false, vertical: true)
            Text(summary)
              .font(.subheadline)
              .foregroundStyle(.secondary)
              .fixedSize(horizontal: false, vertical: true)
          }
          .layoutPriority(1)
          Spacer(minLength: 0)
          disclosureIndicator
        }
      }
    }
    .padding(cardPadding)
    .frame(
      maxWidth: .infinity,
      minHeight: minimumHeight,
      maxHeight: .infinity,
      alignment: contentAxis == .vertical ? .topLeading : .leading
    )
    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
    .overlay {
      RoundedRectangle(cornerRadius: cornerRadius)
        .stroke(.quaternary, lineWidth: 1)
    }
    .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(Text(entry.label))
    .accessibilityValue(Text(summary))
  }

  private var minimumHeight: CGFloat {
    contentAxis == .vertical ? verticalMinimumHeight : horizontalMinimumHeight
  }

  private var entryIcon: some View {
    Image(hDiarySymbol: entry.symbol)
      .font(.title2)
      .foregroundStyle(Color.accentColor)
      .accessibilityHidden(true)
  }

  private var disclosureIndicator: some View {
    Image(systemName: "chevron.forward")
      .font(.footnote.bold())
      .foregroundStyle(.tertiary)
      .accessibilityHidden(true)
  }
}

#endif
