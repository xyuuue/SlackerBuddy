// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "MacPet",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "MacPet", targets: ["MacPet"])
    ],
    targets: [
        .executableTarget(
            name: "MacPet",
            path: "Sources/MacPet"
        ),
        .testTarget(
            name: "MacPetTests",
            dependencies: ["MacPet"],
            path: "Tests/MacPetTests"
        )
    ]
)
