// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "SwiftFileBuilder",
    products: [
        .library(
            name: "SwiftFileBuilder",
            targets: ["SwiftFileBuilder"]
        ),
    ],
    targets: [
        .target(
            name: "SwiftFileBuilder"
        ),
        .testTarget(
            name: "SwiftFileBuilderTests",
            dependencies: [
                "SwiftFileBuilder",
            ]
        ),
    ]
)
