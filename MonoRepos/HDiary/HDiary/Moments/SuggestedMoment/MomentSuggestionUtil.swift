//
//  MomentSuggestionUtil.swift
//  HDiary
//
//  Created by tigerguo on 2024/12/23.
//

import Foundation
import HDiaryConstants
import HDiaryModel
import UIKit
#if canImport(JournalingSuggestions)
  import JournalingSuggestions
#endif

#if canImport(JournalingSuggestions)

  @available(iOS 17.2, *)
  enum MomentSuggestionUtil {
    static func momentFrom(suggestion: JournalingSuggestion) async -> Moment {
      let moment = Moment.create(timestamp: suggestion.date?.start ?? .now)
      moment.updateTitle(suggestion.title)
      // Update content from suggestion items
      await withTaskGroup(of: MomentSliceFromSuggestionItem?.self) { group in
        for suggestionItem in suggestion.items {
          group.addTask {
            return await getMomentSlice(from: suggestionItem)
          }
        }
        for await slice in group {
          if let slice {
            if !slice.description.isEmpty {
              moment.updateContent([moment.content, slice.description].filter { !$0.isEmpty }.joined(separator: "\n"))
            }
            for media in slice.medias {
              let thumbnailData150px: Data? = try? UIImage.downsample(imageData: media.data, to: CGSize(width: 150, height: 150))
              let thumbnailData500px: Data? = try? UIImage.downsample(imageData: media.data, to: CGSize(width: 500, height: 500))
              let thumbnailData1000px: Data? = try? UIImage.downsample(imageData: media.data, to: CGSize(width: 1000, height: 1000))

              let mediaItem = MediaItem(
                data: media.data,
                mediaType: .image,
                pathExtension: media.pathExtension,
                thumbnailData150px: thumbnailData150px,
                thumbnailData500px: thumbnailData500px,
                thumbnailData1000px: thumbnailData1000px
              )
              moment.addMedia(mediaItem)
            }
          }
        }
      }
      return moment
    }

    private struct MomentSliceFromSuggestionItem: Sendable {
      struct Media {
        let data: Data
        let mediaType: MediaItem.MediaType
        let pathExtension: String
      }

      let description: String
      let medias: [Media]
    }

    // MARK: handle all kinds of suggestion items

    private static func getMomentSlice(from suggestionItem: JournalingSuggestion.ItemContent) async -> MomentSliceFromSuggestionItem? {
      Log.common.info("getMomentSlice from suggestionItem with representations \(suggestionItem.representations)")
      var slice: MomentSliceFromSuggestionItem?
      if let song = try? await suggestionItem.content(forType: JournalingSuggestion.Song.self) {
        slice = await getMomentSlice(from: song)
      }
      else if let location = try? await suggestionItem.content(forType: JournalingSuggestion.Location.self) {
        slice = await getMomentSlice(from: location)
      }
      else if let motionActivity = try? await suggestionItem.content(forType: JournalingSuggestion.MotionActivity.self) {
        slice = await getMomentSlice(from: motionActivity)
      }
      else if #available(iOS 18.0, *), let genericMedia = try? await suggestionItem.content(forType: JournalingSuggestion.GenericMedia.self) {
        slice = await getMomentSlice(from: genericMedia)
      }
      else if let livePhoto = try? await suggestionItem.content(forType: JournalingSuggestion.LivePhoto.self) {
        slice = await getMomentSlice(from: livePhoto)
      }
      else if let locationGroup = try? await suggestionItem.content(forType: JournalingSuggestion.LocationGroup.self) {
        slice = await getMomentSlice(from: locationGroup)
      }
      else if let photo = try? await suggestionItem.content(forType: JournalingSuggestion.Photo.self) {
        slice = await getMomentSlice(from: photo)
      }
      else if let podcast = try? await suggestionItem.content(forType: JournalingSuggestion.Podcast.self) {
        slice = await getMomentSlice(from: podcast)
      }
      else if #available(iOS 18.0, *), (try? await suggestionItem.content(forType: JournalingSuggestion.Reflection.self)) != nil {
        // Can't handle reflection now
        slice = nil
      }
      else if #available(iOS 18.0, *), let stateOfMind = try? await suggestionItem.content(forType: JournalingSuggestion.StateOfMind.self) {
        // Can't handle reflection now
        slice = await getMomentSlice(from: stateOfMind)
      }
      else if let workout = try? await suggestionItem.content(forType: JournalingSuggestion.Workout.self) {
        slice = await getMomentSlice(from: workout)
      }
      else if let workoutDetails = try? await suggestionItem.content(forType: JournalingSuggestion.Workout.Details.self) {
        slice = getMomentSlice(from: workoutDetails)
      }
      else if let workoutGroup = try? await suggestionItem.content(forType: JournalingSuggestion.WorkoutGroup.self) {
        slice = getMomentSlice(from: workoutGroup)
      }
      else if let image = try? await suggestionItem.content(forType: UIImage.self) {
        slice = getMomentSlice(from: image)
      }

      return slice
    }

    private static func getMomentSlice(from song: JournalingSuggestion.Song) async -> MomentSliceFromSuggestionItem {
      var description = ""
      var media: MomentSliceFromSuggestionItem.Media?
      if let songName = song.song {
        if let artist = song.artist {
          description = String(localized: DiaryStringKey.Moment.Suggestion.descriptionForListening(song: songName, by: artist))
        }
        else {
          description = String(localized: DiaryStringKey.Moment.Suggestion.descriptionForListening(song: songName))
        }
      }
      if let imageUrl = song.artwork {
        do {
          let data = try Data(contentsOf: imageUrl)
          Log.common.info("getMomentSlice from song image url path extension: \(imageUrl.pathExtension, privacy: .public)")
          media = MomentSliceFromSuggestionItem.Media(
            data: data,
            mediaType: .image,
            pathExtension: imageUrl.pathExtension
          )
        }
        catch {
          Log.common.error("Failed to get data from image url for song")
        }
      }
      return MomentSliceFromSuggestionItem(description: description, medias: [media].compactMap { $0 })
    }

    private static func getMomentSlice(from location: JournalingSuggestion.Location) async -> MomentSliceFromSuggestionItem? {
      if let place = (location.place ?? location.city) {
        let description = String(localized: DiaryStringKey.Moment.Suggestion.descriptionForVisiting(place: place))
        return MomentSliceFromSuggestionItem(description: description, medias: [])
      }
      else {
        return nil
      }
    }

    private static func getMomentSlice(from motionActivity: JournalingSuggestion.MotionActivity) async -> MomentSliceFromSuggestionItem {
      var media: MomentSliceFromSuggestionItem.Media?
      if let iconUrl = motionActivity.icon {
        do {
          let data = try Data(contentsOf: iconUrl)

          media = MomentSliceFromSuggestionItem.Media(
            data: data,
            mediaType: .image,
            pathExtension: iconUrl.pathExtension
          )
          Log.common.info("getMomentSlice from motionActivity, image url path extension: \(iconUrl.pathExtension, privacy: .public)")
        }
        catch {
          Log.common.error("Failed to get data from image url for motionActivity")
        }
      }

      let description: String = {
        let stepDescription = motionActivity.steps.formatted(.number)
        let movementTypeString = {
          if #available(iOS 18.0, *) {
            return motionActivity.movementType?.localizedString ?? String(localized: DiaryStringKey.Moment.Suggestion.movementTypeUnknownDescription)
          }
          else {
            return String(localized: DiaryStringKey.Moment.Suggestion.movementTypeUnknownDescription)
          }
        }()
        return String(localized: DiaryStringKey.Moment.Suggestion.descriptionForMotionActivity(stepCount: stepDescription, movementType: movementTypeString))
      }()

      return MomentSliceFromSuggestionItem(description: description, medias: [media].compactMap { $0 })
    }

    @available(iOS 18.0, *)
    private static func getMomentSlice(from genericMedia: JournalingSuggestion.GenericMedia) async -> MomentSliceFromSuggestionItem {
      var description = ""
      var media: MomentSliceFromSuggestionItem.Media?
      if let songName = genericMedia.title {
        if let artist = genericMedia.artist {
          description = String(localized: DiaryStringKey.Moment.Suggestion.descriptionForListening(song: songName, by: artist))
        }
        else {
          description = String(localized: DiaryStringKey.Moment.Suggestion.descriptionForListening(song: songName))
        }
      }
      if let imageUrl = genericMedia.appIcon {
        do {
          let data = try Data(contentsOf: imageUrl)
          Log.common.info("getMomentSlice from GenericMedia, image url path extension: \(imageUrl.pathExtension, privacy: .public)")
          media = MomentSliceFromSuggestionItem.Media(
            data: data,
            mediaType: .image,
            pathExtension: imageUrl.pathExtension
          )
        }
        catch {
          Log.common.error("Failed to get data from image url for genericMedia")
        }
      }
      return MomentSliceFromSuggestionItem(description: description, medias: [media].compactMap { $0 })
    }

    // handle LivePhoto suggestion
    private static func getMomentSlice(from livePhoto: JournalingSuggestion.LivePhoto) async -> MomentSliceFromSuggestionItem? {
      do {
        let data = try Data(contentsOf: livePhoto.image)
        // Do not support video now
        Log.common.info("getMomentSlice from livePhoto, image url path extension: \(livePhoto.image.pathExtension, privacy: .public)")
        let media = MomentSliceFromSuggestionItem.Media(
          data: data,
          mediaType: .image,
          pathExtension: livePhoto.image.pathExtension
        )
        return MomentSliceFromSuggestionItem(description: "", medias: [media])
      }
      catch {
        Log.common.error("Failed to get data from image url for livePhoto")
        return nil
      }
    }

    // Handle location group
    private static func getMomentSlice(from locationGroup: JournalingSuggestion.LocationGroup) async -> MomentSliceFromSuggestionItem? {
      let locationString = locationGroup.locations.map { $0.place ?? $0.city }.compactMap { $0 }.formatted(.list(type: .and, width: .standard))
      guard !locationString.isEmpty else {
        return nil
      }
      let description = String(localized: DiaryStringKey.Moment.Suggestion.descriptionForVisiting(place: locationString))
      return MomentSliceFromSuggestionItem(description: description, medias: [])
    }

    // Handle Photo suggestion
    private static func getMomentSlice(from photo: JournalingSuggestion.Photo) async -> MomentSliceFromSuggestionItem? {
      do {
        let data = try Data(contentsOf: photo.photo)
        // Do not support video now
        Log.common.info("getMomentSlice from Photo, image url path extension: \(photo.photo.pathExtension, privacy: .public)")
        let media = MomentSliceFromSuggestionItem.Media(
          data: data,
          mediaType: .image,
          pathExtension: photo.photo.pathExtension
        )
        return MomentSliceFromSuggestionItem(description: "", medias: [media])
      }
      catch {
        Log.common.error("Failed to get data from image url for Photo")
        return nil
      }
    }

    // Handle Podcast suggestion
    private static func getMomentSlice(from podcast: JournalingSuggestion.Podcast) async -> MomentSliceFromSuggestionItem {
      var description = ""
      var media: MomentSliceFromSuggestionItem.Media?
      if let episode = podcast.episode {
        description = String(localized: DiaryStringKey.Moment.Suggestion.descriptionForListening(podcast: episode, from: podcast.show))
      }
      if let imageUrl = podcast.artwork {
        do {
          let data = try Data(contentsOf: imageUrl)
          Log.common.info("getMomentSlice from podcast image url path extension: \(imageUrl.pathExtension, privacy: .public)")
          media = MomentSliceFromSuggestionItem.Media(
            data: data,
            mediaType: .image,
            pathExtension: imageUrl.pathExtension
          )
        }
        catch {
          Log.common.error("Failed to get data from podcast url for song")
        }
      }
      return MomentSliceFromSuggestionItem(description: description, medias: [media].compactMap { $0 })
    }

    // Handle StateOfMind
    @available(iOS 18.0, *)
    private static func getMomentSlice(from stateOfMind: JournalingSuggestion.StateOfMind) async -> MomentSliceFromSuggestionItem? {
      guard let iconUrl = stateOfMind.icon else {
        return nil
      }
      do {
        let data = try Data(contentsOf: iconUrl)
        // Do not support video now
        Log.common.info("getMomentSlice from stateOfMind, image url path extension: \(iconUrl.pathExtension, privacy: .public)")
        let media = MomentSliceFromSuggestionItem.Media(
          data: data,
          mediaType: .image,
          pathExtension: iconUrl.pathExtension
        )
        return MomentSliceFromSuggestionItem(description: "", medias: [media])
      }
      catch {
        Log.common.error("Failed to get data from image url for stateOfMind")
        return nil
      }
    }

    // Handle workout
    private static func getMomentSlice(from workout: JournalingSuggestion.Workout) async -> MomentSliceFromSuggestionItem? {
      var media: MomentSliceFromSuggestionItem.Media?

      if let imageUrl = workout.icon {
        do {
          let data = try Data(contentsOf: imageUrl)
          Log.common.info("getMomentSlice from workout image url path extension: \(imageUrl.pathExtension, privacy: .public)")
          media = MomentSliceFromSuggestionItem.Media(
            data: data,
            mediaType: .image,
            pathExtension: imageUrl.pathExtension
          )
        }
        catch {
          Log.common.error("Failed to get data from workout url for song")
        }
      }

      let description = workout.details.map { getDescriptions(from: $0) } ?? ""
      return MomentSliceFromSuggestionItem(description: description, medias: [media].compactMap { $0 })
    }

    private static func getDescriptions(from workoutDetails: JournalingSuggestion.Workout.Details) -> String {
      var descriptionSlice: [String] = []
      if let activeEnergyBurned = workoutDetails.activeEnergyBurned {
        let energyMeasurement = Measurement(value: activeEnergyBurned.doubleValue(for: .largeCalorie()), unit: UnitEnergy.kilocalories)
        let energyString = energyMeasurement.formatted(.measurement(width: .abbreviated, usage: .workout))
        descriptionSlice.append(energyString)
      }

      if let distance = workoutDetails.distance {
        let distanceMeasurement = Measurement(value: distance.doubleValue(for: .meter()), unit: UnitLength.meters)
        let distanceString = distanceMeasurement.formatted(.measurement(width: .abbreviated, usage: .general))
        descriptionSlice.append(distanceString)
      }

      if let duration = workoutDetails.date?.duration {
        let durationString = Duration.seconds(duration).formatted(.units(width: .narrow))
        descriptionSlice.append(durationString)
      }

      let description = descriptionSlice.joined(separator: "\n")

      return description
    }

    // handle workout detail
    private static func getMomentSlice(from workoutDetails: JournalingSuggestion.Workout.Details) -> MomentSliceFromSuggestionItem {
      let description = getDescriptions(from: workoutDetails)
      return MomentSliceFromSuggestionItem(description: description, medias: [])
    }

    private static func getMomentSlice(from workoutGroup: JournalingSuggestion.WorkoutGroup) -> MomentSliceFromSuggestionItem {
      var media: MomentSliceFromSuggestionItem.Media?

      if let imageUrl = workoutGroup.icon {
        do {
          let data = try Data(contentsOf: imageUrl)
          Log.common.info("getMomentSlice from workoutGroup image url path extension: \(imageUrl.pathExtension, privacy: .public)")
          media = MomentSliceFromSuggestionItem.Media(
            data: data,
            mediaType: .image,
            pathExtension: imageUrl.pathExtension
          )
        }
        catch {
          Log.common.error("Failed to get data from workoutGroup url for song")
        }
      }

      var descriptionSlice: [String] = []
      if let activeEnergyBurned = workoutGroup.activeEnergyBurned {
        let energyMeasurement = Measurement(value: activeEnergyBurned.doubleValue(for: .largeCalorie()), unit: UnitEnergy.kilocalories)
        let energyString = energyMeasurement.formatted(.measurement(width: .abbreviated, usage: .workout))
        descriptionSlice.append(energyString)
      }

      if let duration = workoutGroup.duration {
        let durationString = Duration.seconds(duration).formatted(.units(width: .narrow))
        descriptionSlice.append(durationString)
      }

      let description = descriptionSlice.joined(separator: "\n")
      return MomentSliceFromSuggestionItem(description: description, medias: [media].compactMap { $0 })
    }

    private static func getMomentSlice(from image: UIImage) -> MomentSliceFromSuggestionItem? {
      if let data = image.jpegData(compressionQuality: 0.8) {
        let media = MomentSliceFromSuggestionItem.Media(
          data: data,
          mediaType: .image,
          pathExtension: "jpeg"
        )
        return MomentSliceFromSuggestionItem(description: "", medias: [media])
      }
      return nil
    }
  }

  @available(iOS 18.0, *)
  private extension JournalingSuggestion.MotionActivity.MovementType {
    var localizedString: String {
      switch self {
      case .walking:
        return String(localized: DiaryStringKey.Moment.Suggestion.movementTypeRunningWalkingDescription)
      case .running:
        return String(localized: DiaryStringKey.Moment.Suggestion.movementTypeRunningDescription)
      case .runningWalking:
        return String(localized: DiaryStringKey.Moment.Suggestion.movementTypeRunningWalkingDescription)
      default:
        return String(localized: DiaryStringKey.Moment.Suggestion.movementTypeUnknownDescription)
      }
    }
  }
#endif
