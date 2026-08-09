import Foundation
import HDiaryConstants
import SwiftData

public enum WidgetSnapshotContainer {
  public static let schema = Schema([WidgetParticipantSnapshot.self, WidgetMomentSnapshot.self])

  public static var storeURL: URL {
    AppConstants.groupContainerURL
      .appending(components: "Library", "Application Support", "WidgetSnapshot", "widget-snapshot.sqlite")
  }

  public static func configuration(url: URL, allowsSave: Bool) -> ModelConfiguration {
    ModelConfiguration(
      "WidgetSnapshot",
      schema: schema,
      url: url,
      allowsSave: allowsSave,
      cloudKitDatabase: .none
    )
  }

  public static func makeWriterContainer(at url: URL = storeURL) throws -> ModelContainer {
    try prepareStoreDirectory(for: url)
    return try ModelContainer(for: schema, configurations: [configuration(url: url, allowsSave: true)])
  }

  public static func makeReaderContainer(at url: URL = storeURL) throws -> ModelContainer {
    try ModelContainer(for: schema, configurations: [configuration(url: url, allowsSave: false)])
  }

  private static func prepareStoreDirectory(for url: URL) throws {
    var directoryURL = url.deletingLastPathComponent()
    try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)

    var resourceValues = URLResourceValues()
    resourceValues.isExcludedFromBackup = true
    try directoryURL.setResourceValues(resourceValues)
  }
}
