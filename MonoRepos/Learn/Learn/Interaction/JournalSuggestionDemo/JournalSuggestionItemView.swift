//
//  JournalSuggestionItemView.swift
//  Learn
//
//  Created by tigerguo on 2024/12/23.
//

import SwiftUI

// Why I am doing this?
// https://developer.apple.com/forums/thread/746843?answerId=784514022#784514022
#if canImport(JournalingSuggestions)
  import JournalingSuggestions

  @available(iOS 17.2, *)
  struct JournalSuggestionItemView: View {
    let item: JournalingSuggestion.ItemContent
    @State private var image: UIImage?
    @State private var text: UIImage?
    @State private var assetTypes: [any JournalingSuggestionAsset.Type] = []

    private let allItemTypes: [any JournalingSuggestionAsset.Type] = [
      JournalingSuggestion.Contact.self,
//        JournalingSuggestion.GenericMedia.self,
      JournalingSuggestion.LivePhoto.self,
      JournalingSuggestion.Location.self,
      JournalingSuggestion.LocationGroup.self,
      JournalingSuggestion.MotionActivity.self,
      JournalingSuggestion.Photo.self,
      JournalingSuggestion.Podcast.self,
//        JournalingSuggestion.Reflection.self,
      JournalingSuggestion.Song.self,
//        JournalingSuggestion.StateOfMind.self,
      JournalingSuggestion.Video.self,
      JournalingSuggestion.Workout.self,
      JournalingSuggestion.Workout.Details.self,
      JournalingSuggestion.WorkoutGroup.self,
      UIImage.self,
      SwiftUI.Image.self,
    ]

    var body: some View {
      VStack {
        Text(item.id.uuidString)
        if !assetTypes.isEmpty {
          DisclosureGroup("assets types") {
            ForEach((0 ..< assetTypes.count), id: \.self) { assetTypeIndex in
              Text("\(assetTypes[assetTypeIndex])")
            }
          }
        }
        if let image {
          Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .frame(maxHeight: 200)
        }
      }
      .task {
        for type in allItemTypes {
          if item.hasContent(ofType: type) {
            assetTypes.append(type)
          }
        }
        if item.hasContent(ofType: UIImage.self) {
          do {
            image = try await item.content(forType: UIImage.self)
          }
          catch {
            Log.common.error("Failed to get image: \(error)")
          }
        }
      }
      .task {
        await checkWorkout()
      }
    }

    func checkWorkout() async {
      Log.common.info("checkWorkout for \(item.representations)")
      if let workout = try? await item.content(forType: JournalingSuggestion.Workout.self) {
//            Log.common.info("workout \(workout)")
        if let detail = workout.details {
          if let activeEnergyBurned = detail.activeEnergyBurned {
            let caloriesValue = activeEnergyBurned.doubleValue(for: .largeCalorie())
            let cal = Measurement(value: caloriesValue, unit: UnitEnergy.kilocalories)
            let calString = cal.formatted(.measurement(width: .abbreviated, usage: .workout))
            Log.common.info("calories \(calString, privacy: .public)")
          }
        }
      }
    }
  }
#endif
