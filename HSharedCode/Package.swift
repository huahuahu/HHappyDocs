// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let packageSwiftSettings: [SwiftSetting] = [
  .swiftLanguageMode(.v6),
  .enableUpcomingFeature("StrictConcurrency"),
]

let mainActorPackageSwiftSettings: [SwiftSetting] = packageSwiftSettings + [
  .defaultIsolation(MainActor.self),
]

let package = Package(
  name: "HSharedCode",
  defaultLocalization: "en",
  platforms: [.iOS(.v17), .macOS(.v13)],
  products: [
    // Products define the executables and libraries a package produces, and make them visible to other packages.
    .library(
      name: "HLocalization",
      targets: ["HLocalization"]
    ),
    .library(
      name: "HFoundation",
      targets: ["HFoundation"]
    ),
    .library(
      name: "HMedia",
      targets: ["HMedia"]
    ),
    .library(
      name: "HUIComponent",
      targets: ["HUIComponent"]
    ),
    .library(
      name: "HLocation",
      targets: ["HLocation"]
    ),
  ],
  dependencies: [
    // Dependencies declare other packages that this package depends on.
    // .package(url: /* package url */, from: "1.0.0"),
    .package(url: "https://github.com/scinfu/SwiftSoup.git", .upToNextMinor(from: "2.6.0")),
  ],
  targets: [
    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
    // Targets can depend on other targets in this package, and on products in packages this package depends on.
    .target(
      name: "HLocalization",
      dependencies: [],
      resources: [
        .process("Resources/Localizable.xcstrings"),
      ],
      swiftSettings: packageSwiftSettings
    ),
    .testTarget(
      name: "HLocalizationTests",
      dependencies: ["HLocalization"],
      swiftSettings: packageSwiftSettings
    ),
    .target(
      name: "HFoundation",
      dependencies: ["SwiftSoup"],
      swiftSettings: packageSwiftSettings
    ),
    .testTarget(
      name: "HFoundationTests",
      dependencies: ["HFoundation"],
      swiftSettings: packageSwiftSettings
    ),
    .target(
      name: "HMedia",
      dependencies: ["HFoundation"],
      swiftSettings: packageSwiftSettings
    ),
    .testTarget(
      name: "HMediaTests",
      dependencies: ["HMedia"],
      swiftSettings: packageSwiftSettings
    ),

    .target(
      name: "HUIComponent",
      dependencies: [
        "HLocalization",
        "HFoundation",
        "HMedia",
      ],
      resources: [
        .process("Resources/Localizable.xcstrings"),
      ],
      swiftSettings: mainActorPackageSwiftSettings
    ),
    .testTarget(
      name: "HUIComponentTests",
      dependencies: ["HUIComponent"],
      swiftSettings: packageSwiftSettings
    ),
    .target(
      name: "HLocation",
      dependencies: [],
      swiftSettings: mainActorPackageSwiftSettings
    ),
    .testTarget(
      name: "HLocationTests",
      dependencies: ["HLocation"],
      swiftSettings: packageSwiftSettings
    ),
  ]
)
