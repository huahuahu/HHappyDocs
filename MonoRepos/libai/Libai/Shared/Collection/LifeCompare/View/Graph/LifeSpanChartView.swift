//
//  LifeSpanChartView.swift
//  Libai
//
//  Created by huahuahu on 2022/3/17.
//

import Charts
import SwiftUI

struct LifeSpanChartView: View {
  @Environment(\.layoutDirection) var layoutDirection

  @Binding var isPresenting: Bool
  @State private var selectedYear: Int?

  @ScaledMetric private var chartRowHeight = 60
  private let barChartRation = 0.1
  @ScaledMetric private var selectedYearLineWidth = 2

  let lifeSpans: [LifeSpan]

  private let ageRange: ClosedRange<Int>

  init(isPresenting: Binding<Bool>, lifeSpans: [LifeSpan]) {
    _isPresenting = isPresenting
    self.lifeSpans = lifeSpans
    let minAge = lifeSpans.map(\.birthYear).min() ?? 0
    let maxAage = lifeSpans.map(\.deathYear).max() ?? 0
    ageRange = minAge ... maxAage
  }

  private var chartTitle: String {
    if let selectedYear = selectedYear {
      return "\(selectedYear) 年"
    }
    else {
      return "选择年份来比较"
    }
  }

  private func findYear(location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) -> Int? {
    guard let plotFrame = proxy.plotFrame else {
      return nil
    }
    let relativeXPosition = location.x - geometry[plotFrame].origin.x
    let xValue = proxy.value(atX: relativeXPosition) as Double?
    if let year = xValue?.rounded(.toNearestOrEven) {
      // Find the closest date element.
      return max(ageRange.lowerBound, min(ageRange.upperBound, Int(year)))
    }
    return nil
  }

  @ToolbarContentBuilder
  private var toolbarContent: some ToolbarContent {
    ToolbarItemGroup(placement: .cancellationAction) {
      Button {
        isPresenting = false
      } label: {
        Text(PredefinedString.close)
      }
    }
  }

  private var chart: some View {
    Chart(lifeSpans) { lifeSpan in
      BarMark(
        xStart: .value("出生", lifeSpan.birthYear),
        xEnd: .value("去世", lifeSpan.deathYear),
        y: .value("人物", lifeSpan.name),
        height: .ratio(barChartRation)
      )
      .annotation {
        Text(lifeSpan.annotate(for: selectedYear))
          .font(.caption2)
          .monospacedDigit()
      }
    }
    .chartPlotStyle(content: { plotArea in
      plotArea.frame(height: chartRowHeight * Double(lifeSpans.count))
    })
    .chartYAxis(content: {
      AxisMarks(preset: .extended, position: .leading)
    })
    .chartXScale(domain: ageRange)
    .chartOverlay(content: { chartProxy in
      GeometryReader { geoProxy in
        Rectangle().fill(.clear).contentShape(Rectangle())
          .gesture(
            SpatialTapGesture()
              .onEnded { value in
                let year = findYear(location: value.location, proxy: chartProxy, geometry: geoProxy)
                self.selectedYear = year
              }
              .exclusively(before: DragGesture().onChanged { value in
                self.selectedYear = findYear(location: value.location, proxy: chartProxy, geometry: geoProxy)
              })
          )
      }
    })
    .chartBackground(content: { chartProxy in
      GeometryReader { geoProxy in
        if let selectedYear = selectedYear, let plotFrame = chartProxy.plotFrame {
          let lineHeight = geoProxy[plotFrame].maxY

          let startPositionX1 = chartProxy.position(forX: selectedYear) ?? 0
          let midStartPositionX = startPositionX1 + geoProxy[plotFrame].origin.x

          let lineX = layoutDirection == .rightToLeft ? geoProxy.size.width - midStartPositionX : midStartPositionX

          Rectangle()
            .fill(.quaternary)
            .frame(width: selectedYearLineWidth, height: lineHeight)
            .position(x: lineX, y: lineHeight / 2)
        }
      }
    })
  }

  var body: some View {
    NavigationView {
      VStack {
        Text(chartTitle)
          .monospacedDigit()
        chart
      }
      .padding()
      .toolbar {
        toolbarContent
      }
      .navigationBarTitleDisplayMode(.inline)
    }
  }
}

struct LifeSpanChartView_Previews: PreviewProvider {
  static var previews: some View {
    LifeSpanChartView(isPresenting: .constant(true), lifeSpans: [.libai, .武则天])
  }
}

extension LifeSpan {
  func annotate(for year: Int?) -> String {
    let spanText = "\(birthYear) - \(deathYear)"
    guard let year = year else {
      return spanText
    }

    let addedInfo = {
      if year > deathYear {
        return "去世 \(year - deathYear) 年"
      }
      else if year >= birthYear {
        return "\(year - birthYear + 1) 岁"
      }
      else {
        return ""
      }
    }()
    if addedInfo.isEmpty {
      return spanText
    }

    return "\(spanText) \(addedInfo)"
  }
}
