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
        .library(
            name: "WindowsPlatform",
            targets: ["WindowsPlatform"]
        ),
        .library(
            name: "LinuxPlatform",
            targets: ["LinuxPlatform"]
        ),
        .executable(
            name: "Game",
            targets: ["Game"]
        )
    ],
    targets: [
        // Windows platform implementation - separate compilation unit
        .target(
            name: "WindowsPlatform",
            swiftSettings: [
                .unsafeFlags(["-Ounchecked"], .when(configuration: .release))
            ]
        ),
        // Linux platform implementation - separate compilation unit
        .target(
            name: "LinuxPlatform",
            swiftSettings: [
                .unsafeFlags(["-Ounchecked"], .when(configuration: .release))
            ],
            linkerSettings: [
                .linkedLibrary("X11", .when(platforms: [.linux]))
            ]
        ),
        // Core engine library - depends on platform implementations
        .target(
            name: "GameEngine",
            dependencies: [
                .target(name: "WindowsPlatform", condition: .when(platforms: [.windows])),
                .target(name: "LinuxPlatform", condition: .when(platforms: [.linux]))
            ],
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
