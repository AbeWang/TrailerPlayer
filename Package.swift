// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "TrailerPlayer",
    platforms: [
        .iOS(.v10)
    ],
    products: [
        .library(
            name: "TrailerPlayer",
            targets: ["TrailerPlayer"])
    ],
    targets: [
        .target(
            name:"TrailerPlayer",
            dependencies: []
        )
    ])

