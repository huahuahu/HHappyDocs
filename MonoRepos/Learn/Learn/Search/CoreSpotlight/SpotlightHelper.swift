//
//  SpotlightHelper.swift
//  Learn
//
//  Created by tigerguo on 2025/1/24.
//
// Tasks
// - search text in files (not supported yet)
// - search text in images (not supported yet)
// - semantic search (not supported yet)
// - search suggestion (failed to verify)
//

import CoreSpotlight
import Foundation
import MobileCoreServices
import UIKit

extension SearchDemo {
  enum SpotlightHelper {
    static let customKey = CSCustomAttributeKey(keyName: "com_tiger_suzhou_learn_spotlight")!

    static func searchEvents(_ events: [Event], searchText: String) -> [Event] {
      guard !searchText.isEmpty else {
        return []
      }

      let filtered = events.filter { event in
        event.title.localizedCaseInsensitiveContains(searchText) ||
          event.description.localizedCaseInsensitiveContains(searchText) ||
          event.person.localizedCaseInsensitiveContains(searchText) ||
          event.tag.localizedCaseInsensitiveContains(searchText)
      }

      logger.info("Search performed with text: \(searchText), found \(filtered.count) results")
      return filtered
    }

    static func searchSpotlight(searchText: String) async throws -> [CSSearchableItem] {
      let queryString = "title == \"*\(searchText)*\"cd || contentDescription == \"*\(searchText)*\"c || \(customKey.keyName) == \"*\(searchText)*\"cd"
//        let queryString = "title == \"*\(searchText)*\"cd || contentDescription == \"*\(searchText)*\"c"
//
      let context = CSUserQueryContext()
      context.fetchAttributes = ["title", "contentDescription"]
      context.enableRankedResults = true
      context.maxResultCount = 1
      context.maxSuggestionCount = 12
      if #available(iOS 18.0, *) {
        context.maxRankedResultCount = 1
      }
      else {
        // Fallback on earlier versions
      }
//        if #available(iOS 18.0, *) {
//            context.disableSemanticSearch = false
//        } else {
//            // Fallback on earlier versions
//        }

      let query = CSUserQuery(queryString: queryString, queryContext: context)
      logger.info("search spotlight with text: \(searchText), queryContext: \(context)")
      var foundItems = [CSSearchableItem]()

//        for try await element in query.suggestions {
//            logger.info("suggestion from directly suggestion: \(element.suggestion.localizedAttributedSuggestion)")
//        }
//        logger.info("foundSuggestionCount: \(query.foundSuggestionCount)")
//        query.foundSuggestionCount

      for try await element in query.responses {
        switch element {
        case .item(let item):
          foundItems.append(item.item)
          if #available(iOS 18.0, *) {
            query.userEngaged(item, visibleItems: [item], interaction: .select)
          }
          else {
            // Fallback on earlier versions
          }

          logger.info("item: \(item.item.uniqueIdentifier), itemAttributes: \(item.item.attributeSet), title: \(item.item.attributeSet.title ?? ""), contentDescription: \(item.item.attributeSet.contentDescription ?? "")")
        case .suggestion(let suggestion):
          logger.info("suggestion: \(suggestion.suggestion.localizedAttributedSuggestion)")
          if #available(iOS 18.0, *) {
            query.userEngaged(suggestion, visibleSuggestions: [suggestion], interaction: .select)
          }
          else {
            // Fallback on earlier versions
          }
        @unknown default:
          break
        }
      }

      let beforeSort = foundItems
      foundItems.sort { item1, item2 in

        let result = item1.compare(byRank: item2)
        logger.info("compare result: \(result.rawValue)")
        return result == .orderedAscending
      }
      logger.info("sort result: \(beforeSort) -> \(foundItems)")
      return foundItems
    }

    static func deleteAllEvents() {
      CSSearchableIndex.default().deleteAllSearchableItems { error in
        if let error = error {
          print("Error removing from spotlight: \(error)")
        }
        else {
          print("Successfully removed all items from spotlight")
        }
      }
    }

    // https://betterprogramming.pub/implement-core-spotlight-in-a-swiftui-app-859cb703f55d
    static func indexEvents(_ events: [Event]) {
      CSSearchableIndex.default().deleteAllSearchableItems { error in
        if let error = error {
          print("Error deleting searchable items: \(error)")
        }
      }

      var searchableItems: [CSSearchableItem] = []

      let imageAttributes = CSSearchableItemAttributeSet(contentType: .image)
      imageAttributes.title = "Image Title"
      imageAttributes.contentDescription = "Image Description"
      imageAttributes.thumbnailData = UIImage(named: "CoreSpotlight/thumbnail")?.pngData()
      //
      if let imageData = try? Data(contentsOf: Event.sampleImageUrl) {
        // write image data to temp fle
        let tempUrl = URL.makeTempUrl()
        try? imageData.write(to: tempUrl)
        imageAttributes.contentURL = tempUrl
        searchableItems.append(CSSearchableItem(uniqueIdentifier: "89BB0D9A-EA7D-43D8-8583-8603075541FF", domainIdentifier: "image.test", attributeSet: imageAttributes))
      }

      for event in events {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .text)
        attributeSet.title = event.title
        attributeSet.contentDescription = event.description
        attributeSet.keywords = [event.tag, event.person]
        attributeSet.languages = ["zh-Hans", "en"]
        attributeSet.contentURL = event.contentURL
        attributeSet.actionIdentifiers = ["CS_ACTION_1", "CS_ACTION_2"]
        attributeSet.thumbnailData = UIImage(named: "CoreSpotlight/thumbnail")?.pngData()
        attributeSet.textContent = "\(event.title) \(event.description) \(event.person) \(event.tag)"

        logger.info("add event to spotlight, title: \(event.title), contentDescription: \(event.description), keywords: \(event.tag), \(event.person)")

        if event.id.uuidString == "81BB0D9A-EA7D-43D8-8583-860F3075539D" {
          attributeSet.setValue(
            NSString(string: "myObject.myAttr"),
            forCustomKey: customKey
          )
        }

//                      attributeSet.phoneNumbers = ["1224"]
//                      attributeSet.supportsPhoneCall = true

        let searchableItem = CSSearchableItem(
          uniqueIdentifier: event.id.uuidString,
          domainIdentifier: "com.example.events",
          attributeSet: attributeSet
        )

        searchableItems.append(searchableItem)
      }

      CSSearchableIndex.default().indexSearchableItems(searchableItems) { error in
        if let error = error {
          print("Error indexing items: \(error)")
        }
        else {
          print("Successfully indexed items")
        }
      }
    }
  }
}
