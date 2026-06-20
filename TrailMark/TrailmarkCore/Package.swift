// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TrailmarkCore",
    platforms: [
        .iOS("17.0"),
        .watchOS("10.0")
    ],
    products: [
        // The single shared library imported by BOTH the iOS app and the watchOS app.
        // This is the "kill the redundancy" layer from the curriculum: models, the
        // HealthKit manager, the route engine, the media store, motion + connectivity.
        .library(
            name: "TrailmarkCore",
            targets: ["TrailmarkCore"]
        )
    ],
    targets: [
        .target(
            name: "TrailmarkCore"
        ),
        .testTarget(
            name: "TrailmarkCoreTests",
            dependencies: ["TrailmarkCore"]
        )
    ]
)
