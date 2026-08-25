// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "hs-macos-tracker",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "LogReader", targets: ["LogReader"]),
        .library(name: "GameState", targets: ["GameState"]),
        .library(name: "Visibility", targets: ["Visibility"]),
    ],
    targets: [
        .target(name: "GameState", path: "Core/GameState"),
        .target(name: "Visibility", dependencies: ["GameState"], path: "Core/Visibility"),
        .target(name: "LogReader", dependencies: ["GameState", "Visibility"], path: "Core/LogReader"),
        .testTarget(
            name: "CoreTests",
            dependencies: ["LogReader", "GameState", "Visibility"],
            path: "Tests/CoreTests"
        ),
    ]
)
