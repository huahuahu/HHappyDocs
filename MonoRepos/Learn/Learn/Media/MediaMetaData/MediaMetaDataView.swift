import CoreImage
import CoreLocation
import CoreTransferable
import MapKit
import PhotosUI
import SwiftUI

struct MediaMetaDataView: View {
  @State private var selectedItem: PhotosPickerItem?
  @State private var selectedImageData: Data?
  @State private var photoLocation: CLLocation?
  @State private var address: String?
  @State private var imageURL: URL?

  var body: some View {
    VStack {
      if let selectedImageData,
         let uiImage = UIImage(data: selectedImageData) {
        Image(uiImage: uiImage)
          .resizable()
          .scaledToFit()
          .frame(width: 300, height: 300)
      }
      else {
        Text("No image selected")
          .foregroundColor(.gray)
          .frame(width: 300, height: 300)
          .background(Color.black.opacity(0.1))
      }

      if let location = photoLocation {
        if let address = address {
          Text("Address: \(address)")
            .padding()
        }
        else {
          Text("Location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            .padding()
        }

        Button(action: {
          let placemark = MKPlacemark(coordinate: location.coordinate)
          let mapItem = MKMapItem(placemark: placemark)
          mapItem.name = "Photo Location"
          mapItem.openInMaps(launchOptions: nil)
        }) {
          Text("Open in Maps")
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
      }

      PhotosPicker(
        selection: $selectedItem,
        matching: .images,
        photoLibrary: .shared()
      ) {
        Text("Select a photo")
          .padding()
          .background(Color.blue)
          .foregroundColor(.white)
          .cornerRadius(10)
      }
      .onChange(of: selectedItem) { _, newItem in
        Task {
          if let data = try? await newItem?.loadTransferable(type: Data.self) {
            selectedImageData = data
          }

          address = nil
          imageURL = nil
          do {
            // Attempt to load the item as a URL
            if let fileImage = try await newItem?.loadTransferable(type: FileImage.self) {
              print("Loaded URL: \(fileImage.url)")
              getLocation(from: fileImage.url)
              imageURL = fileImage.url
              if let photoLocation {
                Task {
                  do {
                    try await fetchAddress(from: photoLocation)
                  }
                  catch {
                    Log.common.error("Failed to reverse geocode location: \(error)")
                    address = "Unknown address"
                  }
                }
              }
            }
            else {
              print("No URL found")
            }
          }
          catch {
            print("Failed to load URL: \(error)")
          }
        }
      }

      if let imageURL = imageURL {
        NavigationLink("Show Metadata", destination: ImageMetadataView(imageURL: imageURL))
          .padding()
          .background(Color.green)
          .foregroundColor(.white)
          .cornerRadius(10)
      }
    }
    .padding()
  }

  private func fetchAddress(from location: CLLocation) async throws {
    let geocoder = CLGeocoder()
    let placemarks = try await geocoder.reverseGeocodeLocation(location)
    Log.common.info("find \(placemarks.count) Address")

    if let placemark = placemarks.first {
      address = [
        placemark.name,
        placemark.thoroughfare,
        placemark.subLocality,
        placemark.locality,
        placemark.administrativeArea,
        placemark.country,
      ]
      .compactMap { $0 }
      .joined(separator: ", ")
      Log.common.info("Address: \(address ?? ""), areaOfInterest \(placemark.areasOfInterest?.compactMap { $0 }.joined(separator: ", ") ?? "")")
    }
  }

  private func getLocation(from fileUrl: URL) {
    let image = CIImage(contentsOf: fileUrl)!

    let properties = image.properties

    if let gps = properties[kCGImagePropertyGPSDictionary as String] as? [String: Any],
       let lat = gps[kCGImagePropertyGPSLatitude as String] as? Double,
       let lon = gps[kCGImagePropertyGPSLongitude as String] as? Double {
      let gpsLocation = CLLocation(latitude: lat, longitude: lon)
      let marsLocation = KSCoordinateConverter.marsCoordinate(fromGPSCoordinate: gpsLocation.coordinate)
      photoLocation = CLLocation(latitude: marsLocation.latitude, longitude: marsLocation.longitude)

      print(lat, lon)
    }
  }
}

private struct FileImage: Transferable {
  let url: URL
  static var transferRepresentation: some TransferRepresentation {
    FileRepresentation(contentType: .image) { movie in
      SentTransferredFile(movie.url)
    } importing: { received in

      // Define the path for the "temp" subfolder in the temporary directory
      let tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
      let tempSubfolderURL = tempDirectory.appendingPathComponent("temp")

      // Create the "temp" subfolder if it doesn't exist
      if !FileManager.default.fileExists(atPath: tempSubfolderURL.path) {
        try FileManager.default.createDirectory(at: tempSubfolderURL, withIntermediateDirectories: true, attributes: nil)
      }

      // Generate a unique file name in the "temp" subfolder
      let tempFileURL = tempSubfolderURL.appendingPathComponent(UUID().uuidString).appendingPathExtension(received.file.pathExtension)

      try FileManager.default.copyItem(at: received.file, to: tempFileURL)
      return Self(url: tempFileURL)
    }
  }
}

#Preview {
  MediaMetaDataView()
}
