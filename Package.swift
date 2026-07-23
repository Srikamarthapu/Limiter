// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Limiter",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Limiter", targets: ["Limiter"])
    ],
    targets: [
        .executableTarget(
            name: "Limiter",
            path: "Sources/Limiter"
        ),
        .testTarget(
            name: "LimiterTests",
            dependencies: ["Limiter"],
            path: "Tests/LimiterTests"
        )
    ]
)
