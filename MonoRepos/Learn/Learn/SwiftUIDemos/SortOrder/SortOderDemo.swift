// https://developer.apple.com/design/human-interface-guidelines/context-menus

import SwiftUI

extension SwiftUIDemo {
  @MainActor
  struct SortOrderDemoView: View {
    @State private var sortOrder: SortOrder = .ascending

    var body: some View {
      VStack {
        Text("Sort Order Demo")
        Text("Current Sort Order: \(sortOrder.rawValue)")
      }
      .navigationTitle("Sort Order Demo")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Menu {
            Button(action: { sortOrder = .ascending }) {
              HStack {
                if sortOrder == .ascending {
                  Image(systemName: "checkmark")
                }
                Text("Ascending")
              }
            }
            Button(action: { sortOrder = .descending }) {
              HStack {
                if sortOrder == .descending {
                  Image(systemName: "checkmark")
                }
                Text("Descending")
              }
            }
            Button(action: { sortOrder = .custom }) {
              HStack {
                if sortOrder == .custom {
                  Image(systemName: "checkmark")
                }
                Text("Custom")
              }
            }
          } label: {
            Label("Sort Order", systemImage: "arrow.up.arrow.down")
          }
        }
        additionalMenu()
      }
    }

    private func additionalMenu() -> some ToolbarContent {
      ToolbarItem(placement: .navigationBarTrailing) {
        Menu {
          Button("Option 1") {}
          Menu {
            Button(action: { sortOrder = .ascending }) {
              HStack {
                if sortOrder == .ascending {
                  Image(systemName: "checkmark")
                }
                Text("Ascending")
              }
            }
            Button(action: { sortOrder = .descending }) {
              HStack {
                if sortOrder == .descending {
                  Image(systemName: "checkmark")
                }
                Text("Descending")
              }
            }
            Button(action: { sortOrder = .custom }) {
              HStack {
                if sortOrder == .custom {
                  Image(systemName: "checkmark")
                }
                Text("Custom")
              }
            }
          } label: {
            Label {
//                HStack {
//                Text("Sort Options")
//                Text(selectedSortOrderLabel)
//                  .font(.caption)
//                  .foregroundColor(.secondary)
//              }
              Text(attributedSortOrderLabel)
                .lineLimit(2, reservesSpace: true)
//
            } icon: {
              Image(systemName: "arrow.up.arrow.down")
            }
          }

          Button(action: {}) {
            Label("Help", systemImage: "questionmark.circle")
          }

        } label: {
          Label("Options", systemImage: "ellipsis.circle")
        }
      }
    }

    private var attributedSortOrderLabel: AttributedString {
      var attributedString = AttributedString("Sort Options\n")
      var sortOrderString = AttributedString(selectedSortOrderLabel)
      sortOrderString.font = .caption
      sortOrderString.foregroundColor = .secondary
      attributedString.append(sortOrderString)
      return attributedString
    }

    private var selectedSortOrderLabel: String {
      switch sortOrder {
      case .ascending:
        return "Ascending"
      case .descending:
        return "Descending"
      case .custom:
        return "Custom"
      }
    }
  }

  enum SortOrder: String {
    case ascending = "Ascending"
    case descending = "Descending"
    case custom = "Custom"
  }
}

#Preview {
  SwiftUIDemo.SortOrderDemoView()
}
