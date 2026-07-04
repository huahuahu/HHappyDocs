//
//  SearchDemoView.swift
//  Learn
//
//  Created by tigerguo on 2025/1/23.
//

import SwiftUI

extension SwiftUIDemo {
  enum ProductScope: String, CaseIterable, Identifiable {
    case fruit
    case vegetable
    case meat
    case dairy
    case bakery
    case seafood

    var id: Self {
      self
    }
  }

  enum Hydration: String, Hashable, CaseIterable, Identifiable {
    case hydrated
    case dehydrated

    var id: Self {
      self
    }
  }

  struct Token: Identifiable {
    var value: String

    var id: String {
      value
    }

    var hydration: Hydration = .hydrated
  }

  @MainActor
  struct SearchDemoView: View {
    @State private var searchText = ""
    @State private var scope: ProductScope = .fruit
    @State private var showSearchResult = false

    @State private var tokens: [Token] = [] {
      didSet {
        print("tokens: \(tokens)")
//              print("searchText: \(searchText)")
      }
    }

    let items = ["Apple", "Banana", "Orange", "Grapes", "Pineapple"]

    var filteredItems: [String] {
      if searchText.isEmpty {
        return items
      }
      else {
        return items.filter { $0.localizedCaseInsensitiveContains(searchText) }
      }
    }

    var body: some View {
      List(items, id: \.self) { item in
        Text(item)
      }
      .navigationTitle("Searchable List")
      .overlay {
        overlayView
      }
      .searchable(text: $searchText, editableTokens: $tokens, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search items") { $token in
        tokenView(for: $token)
      }
      .searchSuggestions {
        Section {
          Text("🍎 Apple").searchCompletion(Token(value: "apple"))
          Text("🍐 Orange").searchCompletion("Orange")
          Text("🍌 Banana").searchCompletion("banana")

        } header: {
          Text(verbatim: "Suggestion")
        }
      }
      .searchScopes($scope, activation: .onTextEntry) {
        ForEach(ProductScope.allCases) { scope in
          Text(scope.rawValue).tag(scope)
        }
      }
      .onSubmit(of: .search) {
        submitCurrentSearchQuery()
      }

      .onChange(of: searchText, initial: false) { _, _ in
        onSearchTextChange()
      }
    }

    private func submitCurrentSearchQuery() {
//          logger
      logger.info("submitCurrentSearchQuery: \(searchText)")
      showSearchResult = true
    }

    private func onSearchTextChange() {
      if searchText.contains("Apple") {
        tokens.append(Token(value: "Apple"))
      }
    }

    // picker not working
    @ViewBuilder
    private func tokenView(for token: Binding<Token>) -> some View {
      Picker(selection: token.hydration) {
        ForEach(Hydration.allCases) { hydration in
          switch hydration {
          case .hydrated: Text("Hydrated")
          case .dehydrated: Text("Dehydrated")
          }
        }
      } label: {
        Text(token.value.wrappedValue)
      }
    }

    @ViewBuilder
    private var overlayView: some View {
      SearchResultView(items: filteredItems)
    }
  }

  private struct SearchResultView: View {
    @Environment(\.isSearching) private var isSearching
    @Environment(\.dismissSearch) private var dismissSearch
    @State private var showingDetail = false
    let items: [String]

    var body: some View {
      if isSearching {
        List {
          ForEach(0 ..< items.count, id: \.self) { index in
            searchItemView(for: items[index])
          }
        }
      }
    }

    @ViewBuilder
    func searchItemView(for item: String) -> some View {
      Button {
        showingDetail = true
      } label: {
        Text(item)
      }
      .sheet(isPresented: $showingDetail) {
        SearchResultDetailView(dismissSearch: dismissSearch)
      }
    }
  }

  private struct SearchResultDetailView: View {
    let dismissSearch: DismissSearchAction
    @Environment(\.dismiss) private var dismiss
    var body: some View {
      NavigationStack {
        VStack {
          Text(verbatim: "Search Result Detail View")
        }
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
              dismiss()
            }
          }

          ToolbarItem(placement: .confirmationAction) {
            Button("Done") {
              dismiss()
              dismissSearch()
            }
          }
        }
      }
    }
  }
}

#Preview {
  NavigationStack {
    SwiftUIDemo.SearchDemoView()
  }
}
