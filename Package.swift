// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MarkDownApp",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-markdown.git", from: "0.5.0"),
    ],
    targets: [
        .executableTarget(
            name: "MarkDownApp",
            dependencies: [
                .product(name: "Markdown", package: "swift-markdown"),
            ],
            path: "Sources",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "MarkDownAppTests",
            dependencies: [
                "MarkDownApp",
                .product(name: "Markdown", package: "swift-markdown"),
            ],
            path: "Tests",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
