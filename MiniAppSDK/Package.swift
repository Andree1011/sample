// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MiniAppSDK",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "MiniAppSDK",
            targets: ["MiniAppSDK"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "MiniAppSDK",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "MiniAppSDKTests",
            dependencies: ["MiniAppSDK"],
            path: "Tests"
        )
    ]
)
