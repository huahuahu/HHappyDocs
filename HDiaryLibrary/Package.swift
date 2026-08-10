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
  name: "HDiaryLibrary",
  defaultLocalization: "en",
  platforms: [.iOS(.v17), .macOS(.v14)],
  products: [
    // Products define the executables and libraries a package produces, making them visible to other packages.
    .library(
      name: "HDiaryModel",
      targets: ["HDiaryModel"]
    ),
    .library(
      name: "HDiarySearch",
      targets: ["HDiarySearch"]
    ),
    .library(
      name: "HDiaryConstants",
      targets: ["HDiaryConstants"]
    ),
    .library(
      name: "HDiaryIAP",
      targets: ["HDiaryIAP"]
    ),
    .library(
      name: "HDiaryAppFeature",
      targets: ["HDiaryAppFeature"]
    ),
    .library(
      name: "HDiaryWidgetFeature",
      targets: ["HDiaryWidgetFeature"]
    ),
    .library(
      name: "HDiaryWidgetIntents",
      targets: ["HDiaryWidgetIntents"]
    ),
    .library(
      name: "HDiaryWidgetData",
      targets: ["HDiaryWidgetData"]
    ),
    .library(
      name: "HDiaryWidgetSnapshotSync",
      targets: ["HDiaryWidgetSnapshotSync"]
    ),

  ],
  dependencies: [
    // Dependencies declare other packages that this package depends on.
    // .package(url: /* package url */, from: "1.0.0"),
    .package(name: "HSharedCode", path: "../HSharedCode"),
    .package(url: "https://github.com/apple/swift-algorithms", from: "1.0.0"),
    .package(url: "https://github.com/apple/swift-atomics.git", from: "1.2.0"),
    .package(url: "https://github.com/SFSafeSymbols/SFSafeSymbols", from: "6.2.0"),
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
      ],
      swiftSettings: packageSwiftSettings
    ),
    .target(
      name: "HDiarySearch",
      dependencies: [
        "HDiaryConstants",
        "HDiaryModel",
        .product(name: "Atomics", package: "swift-atomics"),
      ],
      swiftSettings: packageSwiftSettings
    ),
    .testTarget(
      name: "HDiarySearchTests",
      dependencies: [
        "HDiarySearch",
        "HDiaryModel",
        .product(name: "Atomics", package: "swift-atomics"),
      ],
      swiftSettings: packageSwiftSettings
    ),
    .testTarget(
      name: "HDiaryModelTests",
      dependencies: [
        "HDiaryModel",
        .product(name: "HFoundation", package: "HSharedCode"),
      ],
      swiftSettings: packageSwiftSettings
    ),
    .target(
      name: "HDiaryConstants",
      dependencies: [
        .product(name: "HUIComponent", package: "HSharedCode"),
        .product(name: "Atomics", package: "swift-atomics"),
      ],
      swiftSettings: packageSwiftSettings
    ),
    .testTarget(
      name: "HDiaryConstantsTests",
      dependencies: [
        "HDiaryConstants",
      ],
      swiftSettings: packageSwiftSettings
    ),
    .target(
      name: "HDiaryIAP",
      dependencies: [
        "HDiaryConstants",
      ],
      resources: [
        .process("Resources"),
      ],
      swiftSettings: packageSwiftSettings
    ),
    .testTarget(
      name: "HDiaryIAPTests",
      dependencies: [
        "HDiaryConstants",
        "HDiaryIAP",
      ],
      swiftSettings: packageSwiftSettings
    ),
    .target(
      name: "HDiaryAppFeature",
      dependencies: [
        "HDiaryConstants",
        "HDiaryIAP",
        "HDiaryModel",
        "HDiarySearch",
        "HDiaryWidgetSnapshotSync",
        .product(name: "HFoundation", package: "HSharedCode"),
        .product(name: "HLocalization", package: "HSharedCode"),
        .product(name: "HMedia", package: "HSharedCode"),
        .product(name: "HUIComponent", package: "HSharedCode"),
        .product(name: "SFSafeSymbols", package: "SFSafeSymbols"),
      ],
      swiftSettings: mainActorPackageSwiftSettings
    ),
    .target(
      name: "HDiaryWidgetFeature",
      dependencies: [
        "HDiaryConstants",
        "HDiaryWidgetData",
        "HDiaryWidgetIntents",
      ],
      swiftSettings: mainActorPackageSwiftSettings
    ),
    .target(
      name: "HDiaryWidgetIntents",
      dependencies: [
        "HDiaryConstants",
        "HDiaryWidgetData",
      ],
      swiftSettings: mainActorPackageSwiftSettings
    ),
    .target(
      name: "HDiaryWidgetData",
      dependencies: [
        "HDiaryConstants",
      ],
      swiftSettings: packageSwiftSettings
    ),
    // 主 App 专用：监听主 Store 变化并投影到独立的 Widget snapshot Store；
    // Widget Extension 只依赖 HDiaryWidgetData，不依赖此同步模块。
    .target(
      name: "HDiaryWidgetSnapshotSync",
      dependencies: [
        "HDiaryConstants",
        "HDiaryModel",
        "HDiaryWidgetData",
      ],
      swiftSettings: mainActorPackageSwiftSettings
    ),
    .testTarget(
      name: "HDiaryWidgetDataTests",
      dependencies: [
        "HDiaryWidgetData",
      ],
      swiftSettings: packageSwiftSettings
    ),
    .testTarget(
      name: "HDiaryWidgetSnapshotSyncTests",
      dependencies: [
        "HDiaryModel",
        "HDiaryWidgetData",
        "HDiaryWidgetSnapshotSync",
      ],
      swiftSettings: packageSwiftSettings
    ),
    .testTarget(
      name: "HDiaryAppFeatureTests",
      dependencies: [
        "HDiaryAppFeature",
        "HDiaryConstants",
        "HDiaryModel",
        "HDiaryWidgetData",
        "HDiaryWidgetIntents",
      ],
      swiftSettings: packageSwiftSettings
    ),
  ]
)
