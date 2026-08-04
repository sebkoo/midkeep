// swift-tools-version:6.0

import PackageDescription

let package = Package(
    name: "midkeep",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "MidkeepKit", targets: ["MidkeepKit"]),
        .library(name: "MidkeepUI", targets: ["MidkeepUI"]),
        .library(name: "MidkeepApp", targets: ["MidkeepApp"]),
    ],
    targets: [
        .target(name: "MidkeepKit"),
        .target(name: "MidkeepUI", dependencies: ["MidkeepKit"]),
        .target(name: "MidkeepApp", dependencies: ["MidkeepUI"]),
        .testTarget(
            name: "MidkeepKitTests",
            dependencies: ["MidkeepKit"],
            resources: [.copy("Fixtures")]
        ),
    ]
)
