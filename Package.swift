// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SlackerBuddy",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "SlackerBuddy", targets: ["SlackerBuddy"]),
        .library(name: "SlackerBuddyCore", targets: ["SlackerBuddyCore"]),
        .executable(name: "SlackerBuddyTestRunner", targets: ["SlackerBuddyTestRunner"])
    ],
    targets: [
        .executableTarget(
            name: "SlackerBuddy",
            dependencies: ["SlackerBuddyCore"],
            path: "Sources/SlackerBuddy"
        ),
        .target(
            name: "SlackerBuddyCore",
            path: "Sources/SlackerBuddyCore"
        ),
        .executableTarget(
            name: "SlackerBuddyTestRunner",
            dependencies: ["SlackerBuddyCore"],
            path: "Tests/SlackerBuddyTestRunner"
        )
    ]
)
