// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PythonConsole",
    platforms: [.macOS(.v14), .iOS(.v17), .visionOS(.v1)],
    products: [
        .library(
            name: "PythonConsole",
            targets: ["PythonConsole"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/felfoldy/DebugTools", .upToNextMajor(from: "0.2.2")),
        .package(url: "https://github.com/felfoldy/PythonTools", branch: "main"),
        .package(url: "https://github.com/raspu/Highlightr", .upToNextMajor(from: "2.2.0"))
    ],
    targets: [
        .target(
            name: "PythonConsole",
            dependencies: ["DebugTools", "PythonTools", "Highlightr"],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "PythonConsoleTests",
            dependencies: ["PythonConsole"]
        ),
    ]
)
