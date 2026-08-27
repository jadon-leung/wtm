// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Onboarding",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "Onboarding", targets: ["Onboarding"])
    ],
    dependencies: [
        .package(path: "../WTMCore")
    ],
    targets: [
        .target(
            name: "Onboarding",
            dependencies: ["WTMCore"]
        ),
        .testTarget(
            name: "OnboardingTests",
            dependencies: ["Onboarding"]
        )
    ]
)
