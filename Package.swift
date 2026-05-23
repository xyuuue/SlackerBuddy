// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "MacPet",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "MacPet", targets: ["MacPet"]),
        .library(name: "MacPetCore", targets: ["MacPetCore"]),
        .executable(name: "MacPetTestRunner", targets: ["MacPetTestRunner"])
    ],
    targets: [
        .executableTarget(
            name: "MacPet",
            dependencies: ["MacPetCore"],
            path: "Sources/MacPet"
        ),
        .target(
            name: "MacPetCore",
            path: "Sources/MacPetCore"
        ),
        .executableTarget(
            name: "MacPetTestRunner",
            dependencies: ["MacPetCore"],
            path: "Tests/MacPetTestRunner"
        )
    ]
)
