//
//  LifeSpanChartsView.swift
//  Libai (iOS)
//
//  Created by huahuahu on 2022/8/28.
//

import Charts
import SwiftUI

struct LifeSpanChartsView: View {
  let lifeSpans: [LifeSpan]
  @Environment(\.layoutDirection) var layoutDirection

  @State private var selectedYear: Int?

  func findYear(location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) -> Int? {
    guard let plotFrame = proxy.plotFrame else {
      return nil
    }
    let relativeXPosition = location.x - geometry[plotFrame].origin.x
    let xValue = proxy.value(atX: relativeXPosition) as Double?
    if let year = xValue?.rounded(.toNearestOrEven) {
      // Find the closest date element.
      return Int(year)
    }
    return nil
  }

  var body: some View {
    VStack {
      Text((selectedYear != nil) ? "\(selectedYear!)" : "比较")
      Chart(lifeSpans) { lifeSpan in
        BarMark(
          xStart: .value("出生", lifeSpan.birthYear),
          xEnd: .value("去世", lifeSpan.deathYear),
          y: .value("人物", lifeSpan.name),
          height: .ratio(0.2)
        )
        .annotation {
          Text("3岁 \(selectedYear ?? -1)")
            .font(.caption2)
        }
        //            .foregroundStyle(Color.red) // HERE

        //            PointMark(x: .value("出生", lifeSpan.birthYear), y: .value("人物", lifeSpan.name))
        //                .foregroundStyle(.red)
      }
      .chartPlotStyle(content: { plotArea in
        plotArea.frame(height: 30 * Double(lifeSpans.count))

      })
      .chartYAxis(content: {
        AxisMarks(preset: .extended, position: .leading)
      })
      .chartXScale(domain: 624 ... 762)
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
    }
    .chartBackground(content: { chartProxy in
      GeometryReader { geoProxy in
        if let selectedYear = selectedYear, let plotFrame = chartProxy.plotFrame {
          let lineHeight = geoProxy[plotFrame].maxY

          let startPositionX1 = chartProxy.position(forX: selectedYear) ?? 0
          let midStartPositionX = startPositionX1 + geoProxy[plotFrame].origin.x

          let lineX = layoutDirection == .rightToLeft ? geoProxy.size.width - midStartPositionX : midStartPositionX

          Rectangle()
            .fill(.quaternary)
            .frame(width: 2, height: lineHeight)
            .position(x: lineX, y: lineHeight / 2)
        }
      }
    })
    .padding()
  }
}

struct LifeSpanChartsView_Previews: PreviewProvider {
  static var previews: some View {
    LifeSpanChartsView(lifeSpans: [.libai, .武则天])
  }
}
