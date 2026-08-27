// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Preferences",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "Preferences", targets: ["Preferences"])
    ],
    dependencies: [
        .package(path: "../WTMCore")
    ],
    targets: [
        .target(
            name: "Preferences",
            dependencies: ["WTMCore"]
        ),
        .testTarget(
            name: "PreferencesTests",
            dependencies: ["Preferences"]
        )
    ]
)
