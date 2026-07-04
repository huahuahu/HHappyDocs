// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "HDocLibrary",
  defaultLocalization: "en",
  platforms: [.iOS(.v17), .macOS(.v13)],
  products: [
    // Products define the executables and libraries a package produces, making them visible to other packages.
    .library(
      name: "HDocAppConstants",
      targets: ["HDocAppConstants"]
    ),
    .library(
      name: "HDocModel",
      targets: ["HDocModel"]
    ),
    .library(
      name: "HDocSharedView",
      targets: ["HDocSharedView"]
    ),
    .library(
      name: "HDocIAP",
      targets: ["HDocIAP"]
    ),
    .library(
      name: "HDocLocation",
      targets: ["HDocLocation"]
    ),
  ],
  dependencies: [
    .package(name: "HSharedCode", path: "../../../HSharedCode"),
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .target(
      name: "HDocAppConstants",
      dependencies: [
        .product(name: "HFoundation", package: "hsharedcode"),
      ]
    ),
    .testTarget(
      name: "HDocAppConstantsTests",
      dependencies: ["HDocAppConstants"]
    ),
    .target(
      name: "HDocModel",
      dependencies: [
        "HDocAppConstants",
      ]
    ),
    .testTarget(
      name: "HDocModelTests",
      dependencies: ["HDocModel"]
    ),
    .target(
      name: "HDocSharedView",
      dependencies: [
        "HDocAppConstants",
      ]
    ),
    .testTarget(
      name: "HDocSharedViewTests",
      dependencies: ["HDocSharedView"]
    ),
    .target(
      name: "HDocIAP",
      dependencies: [
        .product(name: "HFoundation", package: "hsharedcode"),
        "HDocAppConstants",
      ]
    ),
    .testTarget(
      name: "HDocIAPTests",
      dependencies: ["HDocIAP"]
    ),
    .target(
      name: "HDocLocation",
      dependencies: [
        .product(name: "HFoundation", package: "hsharedcode"),
        .product(name: "HLocation", package: "hsharedcode"),
        "HDocAppConstants",
        "HDocModel",
      ]
    ),
    .testTarget(
      name: "HDocLocationTests",
      dependencies: ["HDocLocation"]
    ),
  ]
)
