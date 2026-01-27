// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Game",
    products: [
        .library(
            name: "GameEngine",
            targets: ["GameEngine"]
        ),
        .executable(
            name: "Game",
            targets: ["Game"]
        )
    ],
    targets: [
        // Core engine library - recompiled only when engine code changes
        .target(
            name: "GameEngine",
            swiftSettings: [
                .unsafeFlags(["-Ounchecked"], .when(configuration: .release))
            ]
        ),
        // Game executable - depends on engine, recompiled when game code changes
        .executableTarget(
            name: "Game",
            dependencies: ["GameEngine"],
            swiftSettings: [
                .unsafeFlags(["-Ounchecked"], .when(configuration: .release))
            ]
        ),
        // Tests for the engine
        .testTarget(
            name: "GameEngineTests",
            dependencies: ["GameEngine"]
        ),
    ]
)
