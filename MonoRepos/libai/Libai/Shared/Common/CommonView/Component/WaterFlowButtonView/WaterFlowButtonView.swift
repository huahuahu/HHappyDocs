//
//  WaterFlowButtonView.swift
//  Libai (iOS)
//
//  Created by tigerguo on 2022/4/28.
//
// Replaced by HFlowLayout
import SwiftUI

struct WaterFlowButtonView: View {
  init(items: [Self.Item], config: Self.Config) {
    self.items = items
    self.config = config
  }

  @StateObject private var store = WaterFlowButtonStore()

  let items: [Item]
  let config: Config

  func width(for item: Item) -> Double? {
    store.textWidthMap[item.text]
  }

  private func itemView(_ item: Item) -> some View {
    let borderColor = item.selected ? config.selectedBorderColor : config.borderColor
    let textColor = item.selected ? config.selectedTextColor : config.textColor
    let backgroundColor = item.selected ? config.selectedBackgroundColor : config.backgroundColor
    return
      Button {
        print("tapped ")
        item.onTap()
      } label: {
        Text(item.text)
          .lineLimit(1)
          .font(config.swifUIFont)
          .frame(width: width(for: item).map { CGFloat($0) })
          .padding([.horizontal], config.padding)
          .padding([.vertical], config.verticalPadding)
          .background(backgroundColor)
          .foregroundColor(textColor)
          .cornerRadius(config.margin)
          .overlay(
            RoundedRectangle(cornerRadius: config.margin)
              .stroke(borderColor, lineWidth: 1)
          )
      }
  }

  private func content(_ rows: [[Item]]) -> some View {
    VStack {
      ForEach(0 ..< rows.count, id: \.self) { rowIndex in
        HStack(spacing: config.margin) {
          ForEach(0 ..< rows[rowIndex].count, id: \.self) {
            columnIndex in
            itemView(rows[rowIndex][columnIndex])
          }
        }
        .frame(alignment: .center)
      }
    }
  }

  @ViewBuilder
  var contentView: some View {
    if let rows = store.result {
      content(rows)
    }
    else {
      LoadingView()
        .frame(height: 30)
    }
  }

  var body: some View {
    contentView
      .onChange(of: items) { _, newItems in
        store.updateRawTexts(items: newItems, config: config)
      }
      .onChange(of: config) { _, newValue in
        store.updateRawTexts(items: items, config: newValue)
      }
      .onAppear {
        store.updateRawTexts(items: items, config: config)
      }
  }
}

extension WaterFlowButtonView {
  struct Item: Equatable {
    static func == (lhs: WaterFlowButtonView.Item, rhs: WaterFlowButtonView.Item) -> Bool {
      lhs.text == rhs.text
        && lhs.selected == rhs.selected
    }

    init(text: String, selected: Bool = false, onTap: @escaping () -> Void) {
      self.text = text
      self.onTap = onTap
      self.selected = selected
    }

    let text: String
    var selected = false
    var onTap: () -> Void
  }

  struct Config: Hashable {
    let verticalPadding: Double
    let padding: Double
    let margin: Double
    let font: UIFont
    let containerWidth: Double
    let textColor: Color
    let selectedTextColor: Color
    let backgroundColor: Color
    let selectedBackgroundColor: Color
    let borderColor: Color
    let selectedBorderColor: Color

    var swifUIFont: Font {
      if font == UIFont.preferredFont(forTextStyle: .body) {
        return .body
      }
      else if font == UIFont.preferredFont(forTextStyle: .headline) {
        return .headline
      }
      else if font == UIFont.preferredFont(forTextStyle: .subheadline) {
        return .subheadline
      }

      hAssertFailure("unhandled font \(font)")
      return .body
    }
  }
}

struct WaterFlowButtonView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      GeometryReader { proxy in
        WaterFlowButtonView(
          items: [],
          config: WaterFlowButtonView.Config(
            verticalPadding: 20,
            padding: 5,
            margin: 10,
            font: UIFont.preferredFont(forTextStyle: .body),
            containerWidth: proxy.size.width,
            textColor: .primary,
            selectedTextColor: .red,
            backgroundColor: .gray,
            selectedBackgroundColor: .pink,
            borderColor: .blue,
            selectedBorderColor: .red
          )
        )
      }
      .navigationTitle("Test")
    }
  }
}
