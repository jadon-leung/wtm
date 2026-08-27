// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ItineraryPlanner",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "ItineraryPlanner", targets: ["ItineraryPlanner"])
    ],
    dependencies: [
        .package(path: "../WTMCore")
    ],
    targets: [
        .target(
            name: "ItineraryPlanner",
            dependencies: ["WTMCore"]
        ),
        .testTarget(
            name: "ItineraryPlannerTests",
            dependencies: ["ItineraryPlanner"]
        )
    ]
)
