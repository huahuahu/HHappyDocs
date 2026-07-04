//
//  LocalizedString.swift
//  SharedExifPackage
//
//  Created by tigerguo on 2025/3/7.
//
import Foundation

private class StringBundle {
  static var bundle: LocalizedStringResource.BundleDescription { .forClass(StringBundle.self) }
}

// swiftlint:disable line_length
enum ExifString {
  public static let testString = LocalizedStringResource("testString", table: "Localizable", bundle: StringBundle.bundle, comment: "String for testing")
  enum Common {
    public static let settings = LocalizedStringResource("Settings", table: "Localizable", bundle: StringBundle.bundle, comment: "Title for Settings")
    public static let appNameViewer = LocalizedStringResource("Exif Viewer", table: "Localizable", bundle: StringBundle.bundle, comment: "App name for Viewer")
    public static let appNameEditor = LocalizedStringResource("Exif Editor", table: "Localizable", bundle: StringBundle.bundle, comment: "App name for Editor")
    public static let share = LocalizedStringResource("Share", table: "Localizable", bundle: StringBundle.bundle, comment: "Title for Share")
    public static let cancel = LocalizedStringResource("Cancel", table: "Localizable", bundle: StringBundle.bundle, comment: "Title for Cancel")
    public static let close = LocalizedStringResource("Close", table: "Localizable", bundle: StringBundle.bundle, comment: "Title for Close")
    public static let save = LocalizedStringResource("Save", table: "Localizable", bundle: StringBundle.bundle, comment: "Title for Save")
    // 通用错误标题（当发生未预期的错误时显示）
    public static let errorTitle = LocalizedStringResource(
      "An Error Occurred",
      table: "Localizable",
      bundle: StringBundle.bundle,
      comment: "Generic error title displayed when an unexpected error occurs in the application"
    )

    // Album name for storing edited images
    public static let editedAlbumName = LocalizedStringResource(
      "PicPeek Edits",
      table: "Localizable",
      bundle: StringBundle.bundle,
      comment: "Name of the album where edited images are stored"
    )
  }

  enum PhotoPicker {
    public static let label = LocalizedStringResource("Select photos", table: "Localizable", bundle: StringBundle.bundle, comment: "Title for Photo Picker to select photos")
  }

  enum PhotoDisplay {
    public static let loadError = LocalizedStringResource("Failed to load photo", table: "Localizable", bundle: StringBundle.bundle, comment: "Text shown to user when failed to load photo")

    public static let deletePhotoDisplay = LocalizedStringResource("Close", table: "Localizable", bundle: StringBundle.bundle, comment: "Text shown to user when user can delete photo from displaying")

    public static let basicInfoLabel = LocalizedStringResource("Basic Info", table: "Localizable", bundle: StringBundle.bundle, comment: "Title for basic information section")
  }

  enum Share {
    // label for share with metadata
    public static let withMetadata = LocalizedStringResource("Share with Metadata", table: "Localizable", bundle: StringBundle.bundle, comment: "Title for share with metadata")
    // label for share without metadata
    public static let withoutMetadata = LocalizedStringResource("Share without Metadata", table: "Localizable", bundle: StringBundle.bundle, comment: "Title for share without metadata")
  }

  enum MetaDataEdit {
    // Error title for failed to remove image metadata
    public static let failedToRemoveMetadata = LocalizedStringResource("Failed to remove metadata", table: "Localizable", bundle: StringBundle.bundle, comment: "Title for failed to remove metadata")

    public static let failedToSaveWithoutMetadata = LocalizedStringResource("Failed to save without metadata", table: "Localizable", bundle: StringBundle.bundle, comment: "Title for failed to save without metadata")

    // Error title for no photo permission
    public static let noPhotoPermissionTitle = LocalizedStringResource("No Photo Permission", table: "Localizable", bundle: StringBundle.bundle, comment: "Title for no photo permission")
    // error message for no photo permission
    public static let noPhotoPermissionMessage = LocalizedStringResource("Please allow photo access in settings.", table: "Localizable", bundle: StringBundle.bundle, comment: "Message for no photo permission")

    // Error title for createAlbumFailed
    public static let createAlbumFailedTitle = LocalizedStringResource("Failed to create album", table: "Localizable", bundle: StringBundle.bundle, comment: "Title for failed to create album")
    // Error message for createAlbumFailed
    public static let createAlbumFailedMessage = LocalizedStringResource("Please allow photo access in settings.", table: "Localizable", bundle: StringBundle.bundle, comment: "Message for failed to create album")

    // title for edit metadata button
    public static let editMetadataButtonTitle = LocalizedStringResource("Edit Metadata", table: "Localizable", bundle: StringBundle.bundle, comment: "Title for edit metadata button")

    // a function that returns a localized string when fails to remove exif with error code
    public static func failedToRemoveExif(_ errorCode: Int) -> String {
      let errorMessage = String(localized: "Failed to remove metadata with error code %1$lld", defaultValue: "Failed to remove metadata with error code %1$lld", table: "Localizable", bundle: .module)
      return String(format: errorMessage, errorCode)
    }

    // Success title for saving image without metadata
    public static let saveSuccessTitle = LocalizedStringResource("Save Success", table: "Localizable", bundle: StringBundle.bundle, comment: "Title for successful operation")
    // Success message for saving image without metadata
    public static let saveSuccessMessage = LocalizedStringResource("Image saved successfully.", table: "Localizable", bundle: StringBundle.bundle, comment: "Message shown when image is successfully saved without metadata")

    // Button title for saving image without metadata
    public static let saveWithoutMetadata = LocalizedStringResource("Save Without Metadata", table: "Localizable", bundle: StringBundle.bundle, comment: "Button title for saving image without metadata")

    // title for info button to show metadata's description
    public static let infoButtonTitle = LocalizedStringResource("Info", table: "Localizable", bundle: StringBundle.bundle, comment: "Title for info button to show metadata's description")
  }

  enum MetaData {
    public static let fileName = LocalizedStringResource("File Name", table: "Localizable", bundle: StringBundle.bundle, comment: "Title for file name, fine name is a photo's metadata")
    public static let fileNameDescription = LocalizedStringResource("Name of the photo", table: "Localizable", bundle: StringBundle.bundle, comment: "Description of file name. This is to tell user what file name is.")

    public static let dimension = LocalizedStringResource("Dimensions", table: "Localizable", bundle: StringBundle.bundle, comment: "Title for Dimensions, Dimensions is a photo's metadata, 1920x1080 for example.")
    public static let dimensionDescription = LocalizedStringResource("The dimensions of an image refer to the number of pixels along its horizontal (X-axis) and vertical (Y-axis) directions. The X dimension represents the image’s width, while the Y dimension represents its height. Together, these values determine the image’s resolution and clarity.", table: "Localizable", bundle: StringBundle.bundle, comment: "Description of Dimensions. This is to tell user what Dimensions is.")
    public static let width = LocalizedStringResource("Width", table: "Localizable", bundle: StringBundle.bundle, comment: "Title for Width, Width is a photo's metadata, 1920 for example.")
    public static let widthDescription = LocalizedStringResource("The width of an image refers to the number of pixels along its horizontal (X-axis) direction. It determines the image’s resolution and clarity.", table: "Localizable", bundle: StringBundle.bundle, comment: "Description of Width. This is to tell user what Width is.")
    public static let height = LocalizedStringResource("Height", table: "Localizable", bundle: StringBundle.bundle, comment: "Title for Height, Height is a photo's metadata, 1080 for example.")
    public static let heightDescription = LocalizedStringResource("The height of an image refers to the number of pixels along its vertical (Y-axis) direction. It determines the image’s resolution and clarity.", table: "Localizable", bundle: StringBundle.bundle, comment: "Description of Height. This is to tell user what Height is.")

    public static let size = LocalizedStringResource("Size", table: "Localizable", bundle: StringBundle.bundle, comment: "Title for  Size, Size is a photo's metadata, 2.3MB for example.")
    public static let sizeDescription = LocalizedStringResource("The size of an image refers to the amount of space it takes up on your storage device. The size is measured in bytes, kilobytes (KB), megabytes (MB), gigabytes (GB), or terabytes (TB).", table: "Localizable", bundle: StringBundle.bundle, comment: "Description of Size. This is to tell user what Size is.")

    public static let dateTimeOriginal = LocalizedStringResource("Date Time Original", table: "Localizable", bundle: StringBundle.bundle, comment: "Title for Date Time Original, Date Time Original is a photo's metadata, 2025-03-07 12:00:00 for example.")
    public static let dateTimeOriginalDescription = LocalizedStringResource("The date and time when the original image data was generated. For a digital still camera, the date and time the picture was taken are recorded.", table: "Localizable", bundle: StringBundle.bundle, comment: "Description of Date Time Original. This is to tell user what Date Time Original is.")

    public static let dateTimeDigitized = LocalizedStringResource("Date Time Digitized", table: "Localizable", bundle: StringBundle.bundle, comment: "Title for Date Time Digitized, Date Time Digitized is a photo's metadata, 2025-03-07 12:00:00 for example.")
    public static let dateTimeDigitizedDescription = LocalizedStringResource("The dateTimeDigitized field in an image’s EXIF metadata refers to the date and time when the image was converted into a digital format. This timestamp is recorded when a physical photograph is scanned or a film photo is digitized, marking the moment the image transitioned from an analog to a digital representation. If the image was taken directly with a digital camera, this field may be identical to the original date and time of capture.", table: "Localizable", bundle: StringBundle.bundle, comment: "Description of Date Time Digitized. This is to tell user what Date Time Digitized is.")

    // add Location metadata
    public static let location = LocalizedStringResource("Location", table: "Localizable", bundle: StringBundle.bundle, comment: "Title for Location, Location is a photo's metadata.")
    public static let locationDescription = LocalizedStringResource("The location field in an image’s EXIF metadata refers to the location where the image was taken. This field is recorded when the image is captured with a device that has GPS capabilities, such as a smartphone or digital camera. The location data is stored as latitude and longitude coordinates, which can be used to pinpoint the exact spot where the photo was taken.", table: "Localizable", bundle: StringBundle.bundle, comment: "Description of Location. This is to tell user what Location is.")
  }

  enum Promotion {
    public static let unlockProTitle = LocalizedStringResource(
      "解锁 Pro 版本",
      table: "Localizable",
      bundle: StringBundle.bundle,
      comment: "Title for unlocking Pro version"
    )

    public static let enjoyMoreFeatures = LocalizedStringResource(
      """
      畅享更多功能：
      • 编辑图像元信息
      • 一键分享无元信息图像
      • 更多高级功能敬请期待
      """,
      table: "Localizable",
      bundle: StringBundle.bundle,
      comment: "Description for Pro features"
    )

    public static let getProButton = LocalizedStringResource(
      "立即获取 Pro",
      table: "Localizable",
      bundle: StringBundle.bundle,
      comment: "Button label for purchasing Pro version"
    )
  }
}

extension LocalizedStringResource {
  func hDocLocalized() -> String {
    String(localized: .init(stringLiteral: self.key), bundle: .module)
  }
}
