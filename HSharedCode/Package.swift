// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "HSharedCode",
  defaultLocalization: "en",
  platforms: [.iOS(.v17), .macOS("26.0")],
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
      ]
    ),
    .testTarget(
      name: "HLocalizationTests",
      dependencies: ["HLocalization"]
    ),
    .target(
      name: "HFoundation",
      dependencies: ["SwiftSoup"]
    ),
    .testTarget(
      name: "HFoundationTests",
      dependencies: ["HFoundation"]
    ),
    .target(
      name: "HMedia",
      dependencies: ["HFoundation"]
    ),
    .testTarget(
      name: "HMediaTests",
      dependencies: ["HMedia"]
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
      ]
    ),
    .testTarget(
      name: "HUIComponentTests",
      dependencies: ["HUIComponent"]
    ),
    .target(
      name: "HLocation",
      dependencies: []
    ),
    .testTarget(
      name: "HLocationTests",
      dependencies: ["HLocation"]
    ),
  ]
)
