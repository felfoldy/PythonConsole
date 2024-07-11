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
        .package(url: "https://github.com/felfoldy/LogTools", branch: "main"),
        .package(url: "https://github.com/felfoldy/DebugTools", branch: "logtools"),
        .package(url: "https://github.com/felfoldy/PythonTools", branch: "main"),
        .package(url: "https://github.com/raspu/Highlightr", .upToNextMajor(from: "2.2.0"))
    ],
    targets: [
        .target(
            name: "PythonConsole",
            dependencies: ["LogTools", "DebugTools", "PythonTools", "Highlightr"],
            resources: [
                .copy("Resources/site-packages"),
                .process("Resources/python.png")
            ]
        ),
        .testTarget(
            name: "PythonConsoleTests",
            dependencies: ["PythonConsole"]
        ),
    ]
)
