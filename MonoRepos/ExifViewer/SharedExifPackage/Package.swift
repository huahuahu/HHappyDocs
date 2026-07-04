// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "SharedExifPackage",
  defaultLocalization: "en",
  platforms: [.iOS(.v18), .macOS(.v13)],
  products: [
    // Products define the executables and libraries a package produces, making them visible to other packages.
    .library(
      name: "SharedExifPackage",
      targets: ["SharedExifPackage"]
    ),
  ],
  dependencies: [
    // Dependencies declare other packages that this package depends on.
    // .package(url: /* package url */, from: "1.0.0"),
    .package(name: "HSharedCode", path: "../../../HSharedCode"),
//    .package(url: "https://github.com/apple/swift-algorithms", from: "1.0.0"),
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .target(
      name: "SharedExifPackage",
      dependencies: [
        .product(name: "HFoundation", package: "hsharedcode"),
        .product(name: "HUIComponent", package: "hsharedcode"),
        .product(name: "HLocation", package: "hsharedcode"),
      ],
      resources: [
        .process("Resources"),
      ]
    ),
    .testTarget(
      name: "SharedExifPackageTests",
      dependencies: ["SharedExifPackage"]
    ),
  ]
)
