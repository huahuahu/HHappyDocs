//
//  HFlowLayout.swift
//  Libai (iOS)
//
//  Created by huahuahu on 2022/8/27.
//

import Foundation
import SwiftUI

public struct HFlowLayout: Layout {
  public init(itemSpace: Double, rowSpace: Double, horizontalAlignment: Self.Alignment = .leading) {
    self.itemSpace = itemSpace
    self.rowSpace = rowSpace
    self.horizontalAlignment = horizontalAlignment
  }

  public enum Alignment {
    case leading
    case center
    case trailing
  }

  var itemSpace: Double
  var rowSpace: Double
  var horizontalAlignment: Alignment = .leading

  private func group(_ views: Subviews, with maxWidth: Double) -> [[LayoutSubview]] {
    if views.isEmpty {
      return []
    }
    var result: [[LayoutSubview]] = []
    var currentRow = [LayoutSubview]()
    var currentStart = -itemSpace

    for view in views {
      let size = view.sizeThatFits(.unspecified)
      currentStart += itemSpace + size.width
      if currentStart > maxWidth, !currentRow.isEmpty {
        result.append(currentRow)
        currentRow = [view]
        currentStart = size.width
      }
      else {
        currentRow.append(view)
      }
    }
    result.append(currentRow)
    return result
  }

  public func sizeThatFits(
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache _: inout Void
  ) -> CGSize {
    guard !subviews.isEmpty else { return .zero }

    guard let maxWidth = proposal.width else { return .zero }
    let groupedViews = group(subviews, with: maxWidth)
//    print("view height: \(subviews.map { $0.sizeThatFits(.init(width: maxWidth, height: nil)).height })")
    let height = groupedViews.compactMap { group in
      group.map { view in view.sizeThatFits(.init(width: maxWidth, height: nil)).height }.max()
    }.reduce(0, +)

    return CGSize(width: maxWidth, height: height + rowSpace * Double(groupedViews.count - 1))
  }

  public func placeSubviews(
    in bounds: CGRect,
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache _: inout Void
  ) {
    let groupedViews = group(subviews, with: bounds.width)

    var offSetX: Double = 0
    var offSetY: Double = 0
    var maxHeight: Double = 0
    let maxWidth = proposal.width ?? bounds.width
    for group in groupedViews {
      maxHeight = 0

      let totalWidth: Double = {
        let viewTotalWidth = group.map { $0.sizeThatFits(.init(width: maxWidth, height: nil)).width }.reduce(0, +)
        let paddingTotalWidth = Double(max(group.count - 1, 0)) * itemSpace
        return paddingTotalWidth + viewTotalWidth
      }()

      switch horizontalAlignment {
      case .leading:
        offSetX = 0
      case .center:
        offSetX = (bounds.width - totalWidth) / 2
      case .trailing:
        offSetX = bounds.width - totalWidth
      }

      maxHeight = group.compactMap { view in view.sizeThatFits(.init(width: maxWidth, height: nil)).height }.max() ?? 0
      for view in group {
        let size = view.sizeThatFits(.init(width: maxWidth, height: nil))
        view.place(
          at: CGPoint(x: bounds.origin.x + offSetX, y: bounds.origin.y + offSetY + (maxHeight - size.height) / 2),
          anchor: .topLeading,
          proposal: ProposedViewSize(size)
        )
        offSetX += itemSpace + size.width
      }
      offSetY += maxHeight + rowSpace
    }
  }
}
