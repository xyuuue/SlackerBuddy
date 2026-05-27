// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SlackerBuddyLegacy",
    platforms: [
        .macOS(.v10_13)
    ],
    products: [
        .executable(name: "SlackerBuddyLegacy", targets: ["SlackerBuddyLegacy"])
    ],
    targets: [
        .executableTarget(
            name: "SlackerBuddyLegacy",
            path: "Sources/SlackerBuddyLegacy"
        )
    ]
)
