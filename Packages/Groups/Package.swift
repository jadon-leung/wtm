// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Groups",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "Groups", targets: ["Groups"])
    ],
    dependencies: [
        .package(path: "../WTMCore")
    ],
    targets: [
        .target(
            name: "Groups",
            dependencies: ["WTMCore"]
        ),
        .testTarget(
            name: "GroupsTests",
            dependencies: ["Groups"]
        )
    ]
)
