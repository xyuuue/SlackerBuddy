import Foundation
import SlackerBuddyCore

let petdexCatalogTests: [TestCase] = [
    TestCase(name: "catalog includes builtin pet when directory is empty") {
        let root = try temporaryDirectory()
        let catalog = PetdexCatalog(rootDirectory: root)
        let pets = catalog.loadPets()

        try expect(pets.map(\.id).contains(PetAsset.builtinID), "Expected builtin pet")
        try expect(PetAsset.builtinID == "fufu", "Expected FuFu to be the built-in pet id")
        try expect(pets.first?.displayName == "FuFu", "Expected FuFu to be first")
    },
    TestCase(name: "catalog loads bundled FuFu from app resources") {
        let root = try temporaryDirectory()
        let bundledRoot = try temporaryDirectory()
        try writePetPackage(root: bundledRoot, id: "fufu", displayName: "FuFu", createSprite: true)

        let pets = PetdexCatalog(rootDirectory: root, bundledPetsDirectory: bundledRoot).loadPets()

        try expect(pets.first?.id == "fufu", "Expected bundled FuFu to be first")
        try expect(pets.first?.spriteSheetURL != nil, "Expected bundled FuFu to have a spritesheet")
    },
    TestCase(name: "catalog loads valid pet package") {
        let root = try temporaryDirectory()
        try writePetPackage(root: root, id: "siamese-cat", displayName: "Siamese Cat", createSprite: true)

        let pets = PetdexCatalog(rootDirectory: root).loadPets()

        try expect(pets.contains { $0.id == "siamese-cat" && $0.spriteSheetURL != nil }, "Expected valid Petdex pet")
    },
    TestCase(name: "catalog skips pet package with missing sprite") {
        let root = try temporaryDirectory()
        try writePetPackage(root: root, id: "broken-cat", displayName: "Broken Cat", createSprite: false)

        let pets = PetdexCatalog(rootDirectory: root).loadPets()

        try expect(!pets.contains { $0.id == "broken-cat" }, "Expected missing sprite package to be skipped")
    },
    TestCase(name: "catalog skips pet package with malformed metadata") {
        let root = try temporaryDirectory()
        try writeMalformedPetPackage(root: root, id: "bad-json-cat")

        let pets = PetdexCatalog(rootDirectory: root).loadPets()

        try expect(!pets.contains { $0.id == "bad-json-cat" }, "Expected malformed metadata package to be skipped")
        try expect(pets.map(\.id) == [PetAsset.builtinID], "Expected malformed package to leave only builtin pet")
    },
    TestCase(name: "catalog sorts pets by display name after builtin") {
        let root = try temporaryDirectory()
        try writePetPackage(root: root, id: "z-cat", displayName: "Z Cat", createSprite: true)
        try writePetPackage(root: root, id: "a-cat", displayName: "A Cat", createSprite: true)
        try writePetPackage(root: root, id: "fufu", displayName: "External FuFu", createSprite: true)

        let pets = PetdexCatalog(rootDirectory: root).loadPets()

        try expect(pets.map(\.id).prefix(3) == [PetAsset.builtinID, "a-cat", "z-cat"], "Expected builtin first then sorted pets")
    },
    TestCase(name: "sprite mapping chooses expected atlas rows") {
        try expect(SpriteFrameMapping.row(for: .idle) == 0, "Expected idle row")
        try expect(SpriteFrameMapping.row(for: .sleeping) == 8, "Expected sleeping row")
        try expect(SpriteFrameMapping.row(for: .reminding) == 6, "Expected reminder waiting row")
        try expect(SpriteFrameMapping.row(for: .petting) == 3, "Expected petting waving row")
        try expect(SpriteFrameMapping.row(for: .waking) == 4, "Expected waking jumping row")
        try expect(SpriteFrameMapping.row(for: .dragRunningRight) == 1, "Expected right running row")
        try expect(SpriteFrameMapping.row(for: .automaticRunningRight) == 1, "Expected automatic right running row")
        try expect(SpriteFrameMapping.row(for: .dragRunningLeft) == 2, "Expected left running row")
        try expect(SpriteFrameMapping.row(for: .automaticRunningLeft) == 2, "Expected automatic left running row")
        try expect(SpriteFrameMapping.row(for: .jumping) == 4, "Expected jump row")
        try expect(SpriteFrameMapping.row(for: .failed) == 5, "Expected failed row")
        try expect(SpriteFrameMapping.row(for: .waiting) == 6, "Expected waiting row")
        try expect(SpriteFrameMapping.row(for: .running) == 7, "Expected running row")
        try expect(SpriteFrameMapping.row(for: .reviewing) == 8, "Expected review row")
    }
]

private func temporaryDirectory() throws -> URL {
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("SlackerBuddyTests.\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    return directory
}

private func writePetPackage(root: URL, id: String, displayName: String, createSprite: Bool) throws {
    let packageDirectory = root.appendingPathComponent(id, isDirectory: true)
    let spritesDirectory = packageDirectory.appendingPathComponent("sprites", isDirectory: true)
    try FileManager.default.createDirectory(at: spritesDirectory, withIntermediateDirectories: true)

    let metadata = """
    {
      "id": "\(id)",
      "displayName": "\(displayName)",
      "description": "A test pet",
      "spritesheetPath": "sprites/atlas.png"
    }
    """
    try metadata.write(to: packageDirectory.appendingPathComponent("pet.json"), atomically: true, encoding: .utf8)

    if createSprite {
        try Data([0x89, 0x50, 0x4E, 0x47]).write(to: spritesDirectory.appendingPathComponent("atlas.png"))
    }
}

private func writeMalformedPetPackage(root: URL, id: String) throws {
    let packageDirectory = root.appendingPathComponent(id, isDirectory: true)
    try FileManager.default.createDirectory(at: packageDirectory, withIntermediateDirectories: true)
    try "{".write(to: packageDirectory.appendingPathComponent("pet.json"), atomically: true, encoding: .utf8)
}
