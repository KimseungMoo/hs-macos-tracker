// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "hs-macos-tracker",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "LogReader", targets: ["LogReader"]),
        .library(name: "GameState", targets: ["GameState"]),
        .library(name: "Visibility", targets: ["Visibility"]),
        .library(name: "CardCatalog", targets: ["CardCatalog"]),
        .library(name: "Tracker", targets: ["Tracker"]),
        .library(name: "Arena", targets: ["Arena"]),
        .library(name: "Advice", targets: ["Advice"]),
        .executable(name: "hs-core", targets: ["hs-core"]),
    ],
    targets: [
        .target(name: "GameState", path: "Core/GameState"),
        .target(name: "Visibility", dependencies: ["GameState"], path: "Core/Visibility"),
        .target(name: "LogReader", dependencies: ["GameState", "Visibility"], path: "Core/LogReader"),
        .target(
            name: "CardCatalog",
            dependencies: ["GameState"],
            path: "Data/CardCatalog",
            exclude: ["sample-pack.json"]
        ),
        .target(name: "Tracker", dependencies: ["CardCatalog", "GameState", "Visibility"], path: "Features/Tracker"),
        .target(name: "Arena", dependencies: ["CardCatalog", "GameState"], path: "Features/Arena"),
        .target(name: "Advice", dependencies: ["CardCatalog", "GameState", "Visibility"], path: "Features/Advice"),
        .executableTarget(
            name: "hs-core",
            dependencies: ["Advice", "Arena", "CardCatalog", "GameState", "LogReader", "Tracker", "Visibility"],
            path: "Tools/CLI"
        ),
        .testTarget(
            name: "CoreTests",
            dependencies: ["Advice", "Arena", "CardCatalog", "GameState", "LogReader", "Tracker", "Visibility"],
            path: "Tests/CoreTests"
        ),
    ]
)
