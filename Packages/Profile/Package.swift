// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Profile",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "Profile", targets: ["Profile"])
    ],
    dependencies: [
        .package(path: "../WTMCore")
    ],
    targets: [
        .target(
            name: "Profile",
            dependencies: ["WTMCore"]
        ),
        .testTarget(
            name: "ProfileTests",
            dependencies: ["Profile"]
        )
    ]
)
