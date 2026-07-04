//
//  RawModelDataView.swift
//  HDoc
//
//  Created by tigerguo on 2024/1/5.
//

import HDocAppConstants
import HDocModel
import SwiftData
import SwiftUI

@MainActor
struct RawModelDataView<T: RawData>: View {
  @Environment(\.modelContext) private var modelContext
  @State private var rawData: [T] = []
  @State private var sortOrder: SortOrder = .title

  var body: some View {
    List(rawData) { item in
      NavigationLink {
        ScrollView {
          Text(item.getDetailString())
            .textSelection(.enabled)
        }
        .padding()
        .navigationTitle(item.title)
      } label: {
        cell(for: item, with: sortOrder)
      }
    }
    .toolbar {
      toolBarContent
    }
    .task {
      loadData()
    }
    .onChange(of: sortOrder, { _, _ in
      loadData()
    })
    .navigationTitle(String(describing: (T.self)))
  }

  @ViewBuilder
  private func cell(for item: T, with sortOrder: SortOrder) -> some View {
    switch sortOrder {
    case .id:
      Text(item.uuid.uuidString)
    case .title:
      Text(item.title)
    }
  }

  @ToolbarContentBuilder
  private var toolBarContent: some ToolbarContent {
    ToolbarItem(placement: .primaryAction) {
      Menu {
        Picker(selection: $sortOrder) {
          ForEach(SortOrder.allCases) { order in
            Text(String(describing: order))
              .tag(order)
          }
        } label: {
          Text(verbatim: "Select order")
        }
      } label: {
        Label(
          title: { Text(verbatim: "Sort by") },
          icon: { Image(hdocSymbol: .sort) }
        )
      }
    }
  }

  private func loadData() {
    do {
      rawData = try modelContext.fetch(FetchDescriptor<T>()).sorted {
        switch sortOrder {
        case .id:
          $0.id < $1.id
        case .title:
          $0.title.localizedStandardCompare($1.title) == .orderedAscending
        }
      }
    }
    catch {
      Log.data.error("Failed to fetch data: \(error)")
    }
  }
}

private enum SortOrder: CaseIterable, Identifiable {
  var id: Self {
    self
  }

  case id
  case title
}

protocol RawData: SwiftData.PersistentModel, Encodable {
  var uuid: UUID { get }
  var title: String { get }
}

private extension RawData {
  func getDetailString() -> String {
    do {
      let encoder = JSONEncoder()
      encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
      let formatter = DateFormatter()
      formatter.dateStyle = .full
      formatter.timeStyle = .full

      encoder.dateEncodingStrategy = .formatted(formatter)
      let data = try encoder.encode(self)
      return String(data: data, encoding: .utf8) ?? ""
    }
    catch {
      Log.data.error("failed to encode \(type(of: self)) \(error)")
      return ""
    }
  }
}

extension Symptom: RawData {}

extension Record: RawData {}

extension MedicalStaff: RawData {
  public var title: String {
    name
  }
}

extension MedicalSite: RawData {
  public var title: String { name }
}

extension Patient: RawData {
  public var title: String { name }
}

extension Location: RawData {
  public var title: String { name }
}

extension ParkingLocation: RawData {
  public var title: String { name }
}

#if DEBUG
  #Preview { @MainActor in
    NavigationStack {
      RawModelDataView<Record>()

        .previewEnvironment()
    }
  }

#endif
