import Foundation

public enum DeepLink {
  public static let scheme = "hdiarydl"

  public enum Host: String, RawRepresentable {
    case moment
    case library
    case setting
  }

  public enum MomentTarget: String, RawRepresentable {
    case add
  }

  public static func getAddMomentUrl() -> URL? {
    var urlComponents = URLComponents()
    urlComponents.scheme = Self.scheme
    urlComponents.host = Self.Host.moment.rawValue
    urlComponents.path = "/\(MomentTarget.add.rawValue)"
    return urlComponents.url
  }
}
