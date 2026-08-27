// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "WTMCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "WTMCore", targets: ["WTMCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/supabase/supabase-swift", from: "2.0.0")
    ],
    targets: [
        .target(
            name: "WTMCore",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift")
            ]
        ),
        .testTarget(
            name: "WTMCoreTests",
            dependencies: ["WTMCore"]
        )
    ]
)
