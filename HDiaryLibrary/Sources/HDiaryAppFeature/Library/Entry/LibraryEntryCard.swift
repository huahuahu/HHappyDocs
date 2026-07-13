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
  let summary: LibraryEntrySummary
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
          summaryText
          Spacer(minLength: 0)
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
            summaryText
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .layoutPriority(1)
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
    .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(Text(entry.label))
    .accessibilityValue(summaryAccessibilityValue)
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

  @ViewBuilder
  private var summaryText: some View {
    switch summary {
    case .count(let count):
      Text(count, format: .number)
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
    case .localized(let resource):
      Text(resource)
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
    }
  }

  private var summaryAccessibilityValue: Text {
    switch summary {
    case .count(let count):
      Text(count, format: .number)
    case .localized(let resource):
      Text(resource)
    }
  }
}

#endif
