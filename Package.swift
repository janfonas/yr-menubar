// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "YrMenuBar",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "YrMenuBar", targets: ["YrMenuBar"])
    ],
    targets: [
        .executableTarget(
            name: "YrMenuBar",
            path: "Sources/YrMenuBar",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "YrMenuBarTests",
            dependencies: ["YrMenuBar"],
            path: "Tests/YrMenuBarTests",
            resources: [.process("Fixtures")]
        )
    ]
)
