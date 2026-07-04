//
//  SpotlightDemoView.swift
//  Learn
//
//  Created by tigerguo on 2025/1/24.
//

import CoreSpotlight
import MobileCoreServices
import SwiftUI

extension SearchDemo {
  struct SpotlightDemoView: View {
    @State private var events: [Event] = Event.testEvents
    @State private var searchText = ""
    @State private var filteredEvents: [Event] = []

    var body: some View {
      List(events) { event in
        VStack(alignment: .leading) {
          Text(event.title)
            .font(.headline)
          Text(event.person)
            .font(.subheadline)
          Text(event.tag)
            .font(.caption)
            .foregroundColor(.blue)
          Text(event.description)
            .font(.body)
        }
      }
      .overlay {
        SearchResultsOverlayView(filteredEvents: filteredEvents)
      }
      .navigationTitle("Spotlight Demo")
      .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
      .searchSuggestions({
        List {}
      })
      .onSubmit(of: .search) {
        performSearch()
      }
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button {
            SpotlightHelper.indexEvents(events)
          } label: {
            Image(systemName: "plus.magnifyingglass")
          }
        }

        ToolbarItem(placement: .navigationBarTrailing) {
          Button {
            SpotlightHelper.deleteAllEvents()
          } label: {
            Image(systemName: "minus.magnifyingglass")
              .symbolVariant(.slash)
          }
        }
      }
      .onAppear {
        if #available(iOS 18.0, *) {
          CSUserQuery.prepare()
        }
        else {
          // Fallback on earlier versions
        }
      }
      // when user taps "Search in App" in spotlight search result
      .onContinueUserActivity(CSQueryContinuationActionType, perform: handleSpotlightSearchContinuation)
      // handle when user taps spotlight search result
      .onContinueUserActivity(CSSearchableItemActionType, perform: handleSpotlight)
    }

    func handleSpotlightSearchContinuation(userActivity: NSUserActivity) {
      guard let searchString = userActivity.userInfo?[CSSearchQueryString] as? String else {
        return
      }

      // Continue spotlight search in app
      // Use the search string as per your app's use-case
      logger.info("handleSpotlightSearchContinuation: \(searchString)")
//          print(searchString)
    }

    func handleSpotlight(userActivity: NSUserActivity) {
      // Get selected spotlight search item
      guard let element = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String else {
        return
      }

      // log user activity
      print("handle Spotlight userActivity: \(String(describing: userActivity.userInfo))")

      // If custom action requested, execute it
      if let actionIdentifier = userActivity.userInfo?[CSActionIdentifier] as? String {
        logger.info("handleSpotlight: \(element), actionIdentifier: \(actionIdentifier)")
        if actionIdentifier == "CS_ACTION_1" {
          // Perform action 1
        }
        else if actionIdentifier == "CS_ACTION_2" {
          // Perform action 2
        }
      }
      // Else handle the element
      // Maybe deep-link, or something else entirely
      // This totally depends on your app's use-case
      else {
//              self.selection = Int(element)
      }
    }

    private func performSearch() {
      Task {
        let csItems = try await SpotlightHelper.searchSpotlight(searchText: searchText)
        logger.info("csItems: \(csItems.count), items: \(csItems.map { $0.uniqueIdentifier })")
        for item in csItems {
          // tell the system that the item was recently used
          item.attributeSet.lastUsedDate = Date()
          item.isUpdate = true
        }
        filteredEvents = csItems.compactMap { item in
          Event.testEvents.first { event in
            event.id.uuidString == item.uniqueIdentifier
          }
        }

        logger.info("filteredEvents: \(filteredEvents.count)")
      }
//      filteredEvents = SpotlightHelper.searchEvents(events, searchText: searchText)
    }
  }

  private struct SearchResultsOverlayView: View {
    @Environment(\.isSearching) private var isSearching
    let filteredEvents: [Event]

    var body: some View {
//      let _ = logger.info("isSearching: \(isSearching), filteredEvents: \(filteredEvents.count)")
      if isSearching {
        if filteredEvents.isEmpty {
          List {
            ContentUnavailableView {
              Text(verbatim: "empty search results")
            }
          }
        }
        else {
          List(filteredEvents) { event in
            VStack(alignment: .leading) {
              Text(event.title)
                .font(.headline)
              Text(event.person)
                .font(.subheadline)
              Text(event.tag)
                .font(.caption)
                .foregroundColor(.blue)
              Text(event.description)
                .font(.body)
            }
          }
        }
      }
      else {
        EmptyView()
      }
    }
  }
}

#Preview {
  NavigationStack {
    SearchDemo.SpotlightDemoView()
  }
}
