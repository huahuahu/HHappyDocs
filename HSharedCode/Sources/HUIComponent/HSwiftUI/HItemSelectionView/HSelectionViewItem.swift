//
//  HSelectionViewItem.swift
//
//
//  Created by tigerguo on 2023/8/27.
//

import HLocalization
import ObjectiveC
import SwiftUI

public protocol HSelectionViewItem: Hashable, Identifiable {
  associatedtype Preview: View
  var title: String { get }
  var uuid: UUID { get }
  @MainActor @ViewBuilder func makePreviewView() -> Preview
  var showPreview: Bool { get }
}

public extension HSelectionViewItem {
  @MainActor func makePreviewView() -> some View {
    EmptyView()
  }

  var showPreview: Bool {
    false
  }
}

public struct HSelectionView<Item: HSelectionViewItem>: View {
  private enum SectionID: Hashable {
    case selected
    case unselected
  }

  public struct Config {
    public init(
      title: LocalizedStringResource,
      nothingSelectedText: LocalizedStringResource
    ) {
      self.title = title
      self.nothingSelectedText = nothingSelectedText
    }

    let title: LocalizedStringResource
    let nothingSelectedText: LocalizedStringResource
  }

  public init(
    allItems: [Item],
    initialItems: [Item],
    config: Config,
    onCommit: @escaping ([Item]) -> Void
  ) {
    self.allItems = allItems
    self.initialItems = initialItems
    self.config = config
    self.onCommit = onCommit
  }

  @Environment(\.dismiss) private var dismiss
  let allItems: [Item]
  let initialItems: [Item]

  let config: Config
  @State private var taskFinished = false
  @State private var isInitial = false
  @State private var currentItems: [Item] = []
  @ScaledMetric private var tagHorizontalPadding = 20
  @ScaledMetric private var tagVerticalPadding = 10
  @ScaledMetric private var paddingAfterSelectedTagsView = 20

  @State private var scrolledSectionID: SectionID?
  let onCommit: ([Item]) -> Void

  @Namespace private var animation

  public var body: some View {
    ScrollView {
      VStack(spacing: 0) {
        selectedTagsView
          .padding([.bottom], paddingAfterSelectedTagsView)
          .id(SectionID.selected)
        unselectedTagsView
          .id(SectionID.unselected)
      }
      #if os(iOS)
      .scrollTargetLayout()
      #endif
    }
    #if os(iOS)
    .scrollPosition(id: $scrolledSectionID)
    .scrollIndicatorsFlash(onAppear: true)
    #endif
    .navigationTitle(Text(config.title))
    .toolbar(content: {
      toolBar
    })
    .onAppear {
      if !isInitial {
        currentItems = initialItems
      }
      isInitial = true
    }
  }

  @ViewBuilder
  private var selectedTagsView: some View {
    if currentItems.isEmpty {
      HStack(spacing: 0) {
        Text(config.nothingSelectedText)
        Image(systemName: "arrow.down")
      }
      .font(.callout)
      .foregroundStyle(.gray)
      .padding([.bottom])
    }
    else {
      HFlowLayout(itemSpace: tagHorizontalPadding, rowSpace: tagVerticalPadding, horizontalAlignment: .center) {
        ForEach(currentItems) { item in
          Button {
            onTap(for: item)
          } label: {
            Text(item.title)
              .tagStyle(currentItems.contains(item) ? .selected : .notSelected)
          }
          .contextMenu(menuItems: {
            if item.showPreview {
              Button {
                onTap(for: item)
              } label: {
                Label {
                  Text(HUIComponentString.SelectionView.remove.hDocLocalized())
                } icon: {
                  Image(systemName: "minus").symbolVariant(.circle)
                }
              }
            }
          }, preview: {
            item.makePreviewView()
          })
          .matchedGeometryEffect(id: item.uuid, in: animation)
        }
      }
      .padding(.horizontal)
    }
  }

  @ViewBuilder
  private var unselectedTagsView: some View {
    if unselectedTags.isEmpty {
      EmptyView()
    }
    else {
      HFlowLayout(itemSpace: tagHorizontalPadding, rowSpace: tagVerticalPadding, horizontalAlignment: .center) {
        ForEach(unselectedTags) { item in
          Button {
            onTap(for: item)
          } label: {
            Text(item.title)
              .tagStyle(currentItems.contains(item) ? .selected : .notSelected)
          }
          .contextMenu(menuItems: {
            if item.showPreview {
              Button {
                onTap(for: item)
              } label: {
                Label {
                  Text(HUIComponentString.SelectionView.add.hDocLocalized())
                } icon: {
                  Image(systemName: "plus").symbolVariant(.circle)
                }
              }
            }
          }, preview: {
            item.makePreviewView()
          })
          .matchedGeometryEffect(id: item.uuid, in: animation)
        }
      }
      .padding()
      .background(.black.opacity(0.05))
    }
  }

  private var unselectedTags: [Item] {
    Set(allItems).subtracting(Set(currentItems)).sorted {
      $0.title.localizedStandardCompare($1.title) == .orderedAscending
    }
  }

  @ToolbarContentBuilder
  private var toolBar: some ToolbarContent {
    ToolbarItem(placement: .cancellationAction) {
      Button {
        dismiss()
      } label: {
        Text(HLocalizedString.dismiss)
      }
    }

    ToolbarItem(placement: .confirmationAction) {
      Button {
        onCommit(currentItems)
        dismiss()
        taskFinished = true
      } label: {
        Text(HLocalizedString.confirm)
      }
      #if os(iOS) || os(watchOS)
      .sensoryFeedback(.success, trigger: taskFinished)
      #endif
      .disabled(!confirmButtonEnabled)
    }
  }

  func onTap(for tag: Item) {
    withAnimation(.snappy) {
      if currentItems.contains(tag) {
        currentItems.removeAll { $0 == tag }
      }
      else {
        currentItems.append(tag)
      }
      currentItems = currentItems.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending
      }
      scrolledSectionID = .selected
    }
  }

  private var confirmButtonEnabled: Bool {
    currentItems != initialItems
  }
}

private struct Item: HSelectionViewItem {
  @MainActor func makePreviewView() -> some View {
    VStack {
      Text(title)
      Text(id.uuidString)
    }
    .padding()
  }

  var showPreview: Bool {
    true
  }

  var uuid: UUID = UUID()

  var title: String
  var id: UUID {
    uuid
  }

  static let demo1 = Self(title: "item1")
  static let demo2 = Self(title: "item2")
  static let demo3 = Self(title: "item3")
  static let demo4 = Self(title: "item4")
  static let demo5 = Self(title: "item5")
  static let longTextDemo = Self(title: "阿斯顿发进时代峰峻啊是两地分居啊时代峰峻啊是的发送的附件啊是独家发售的减肥了；啊是剪短发；啊")
}

#Preview {
  return NavigationStack {
    HSelectionView<Item>(
      allItems: [.demo1, .demo2, .demo3],
      initialItems: [.demo1],
      config: .init(title: "选择Item", nothingSelectedText: "从下面选择"),
      onCommit: { newTags in
        print("new tags \(newTags)")
      }
    )
  }
}

#Preview("Long Text") {
  return NavigationStack {
    HSelectionView<Item>(
      allItems: [.demo1, .demo2, .demo3, .longTextDemo],
      initialItems: [.demo1],
      config: .init(title: "选择Item", nothingSelectedText: "从下面选择"),
      onCommit: { newTags in
        print("new tags \(newTags)")
      }
    )
  }
}
