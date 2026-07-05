// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "HDiaryLibrary",
  defaultLocalization: "en",
  platforms: [.iOS(.v17), .macOS(.v13)],
  products: [
    // Products define the executables and libraries a package produces, making them visible to other packages.
    .library(
      name: "HDiaryModel",
      targets: ["HDiaryModel"]
    ),
    .library(
      name: "HDiaryConstants",
      targets: ["HDiaryConstants"]
    ),
    .library(
      name: "HDiaryIAP",
      targets: ["HDiaryIAP"]
    ),

  ],
  dependencies: [
    // Dependencies declare other packages that this package depends on.
    // .package(url: /* package url */, from: "1.0.0"),
    .package(name: "HSharedCode", path: "../HSharedCode"),
    .package(url: "https://github.com/apple/swift-algorithms", from: "1.0.0"),
  ],

  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .target(
      name: "HDiaryModel",
      dependencies: [
        "HDiaryConstants",
        .product(name: "HFoundation", package: "HSharedCode"),
        .product(name: "HMedia", package: "HSharedCode"),
        .product(name: "Algorithms", package: "swift-algorithms"),
      ],
      resources: [
        .process("Resources"),
      ]
    ),
    .testTarget(
      name: "HDiaryModelTests",
      dependencies: [
        "HDiaryModel",
        .product(name: "HFoundation", package: "HSharedCode"),
      ]
    ),
    .target(
      name: "HDiaryConstants",
      dependencies: [
        .product(name: "HUIComponent", package: "HSharedCode"),
      ],
      resources: [
        .process("Resources"),
      ]
    ),
    .testTarget(
      name: "HDiaryConstantsTests",
      dependencies: [
        "HDiaryConstants",
      ]
    ),
    .target(
      name: "HDiaryIAP",
      dependencies: [
        "HDiaryConstants",
      ],
      resources: [
        .process("Resources"),
      ]
    ),
    .testTarget(
      name: "HDiaryIAPTests",
      dependencies: [
        "HDiaryIAP",
      ]
    ),
  ]
)
