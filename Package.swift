// swift-tools-version: 5.9
import PackageDescription

// This package exists to unit-test the SwiftUI-free game engine on macOS via `swift test`.
// The Xcode app target compiles the same `Engine/` sources for iOS.
let package = Package(
    name: "TetrisEngine",
    products: [
        .library(name: "TetrisEngine", targets: ["TetrisEngine"]),
    ],
    targets: [
        .target(name: "TetrisEngine", path: "Engine"),
        .testTarget(name: "TetrisEngineTests", dependencies: ["TetrisEngine"], path: "EngineTests"),
    ]
)
