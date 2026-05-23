// swift-tools-version: 5.9

import PackageDescription

let developerFrameworksPath = "/Library/Developer/CommandLineTools/Library/Developer/Frameworks"
let developerLibrariesPath = "/Library/Developer/CommandLineTools/Library/Developer/usr/lib"

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
            path: "Tests/MacPetTests",
            swiftSettings: [
                .unsafeFlags(["-F", developerFrameworksPath])
            ],
            linkerSettings: [
                .unsafeFlags([
                    "-F", developerFrameworksPath,
                    "-Xlinker", "-rpath", "-Xlinker", developerFrameworksPath,
                    "-Xlinker", "-rpath", "-Xlinker", developerLibrariesPath
                ])
            ]
        )
    ]
)
