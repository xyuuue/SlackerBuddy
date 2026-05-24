import Foundation
import MacPetCore

let petdexCatalogTests: [TestCase] = [
    TestCase(name: "catalog includes builtin pet when directory is empty") {
        let root = try temporaryDirectory()
        let catalog = PetdexCatalog(rootDirectory: root)
        let pets = catalog.loadPets()

        try expect(pets.map(\.id).contains(PetAsset.builtinID), "Expected builtin pet")
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
    TestCase(name: "catalog sorts pets by display name after builtin") {
        let root = try temporaryDirectory()
        try writePetPackage(root: root, id: "z-cat", displayName: "Z Cat", createSprite: true)
        try writePetPackage(root: root, id: "a-cat", displayName: "A Cat", createSprite: true)

        let pets = PetdexCatalog(rootDirectory: root).loadPets()

        try expect(pets.map(\.id).prefix(3) == [PetAsset.builtinID, "a-cat", "z-cat"], "Expected builtin first then sorted pets")
    },
    TestCase(name: "sprite mapping chooses expected atlas rows") {
        try expect(SpriteFrameMapping.row(for: .idle) == 0, "Expected idle row")
        try expect(SpriteFrameMapping.row(for: .reminding) == 6, "Expected reminder waiting row")
        try expect(SpriteFrameMapping.row(for: .petting) == 3, "Expected petting waving row")
        try expect(SpriteFrameMapping.row(for: .waking) == 4, "Expected waking jumping row")
    }
]

private func temporaryDirectory() throws -> URL {
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("MacPetTests.\(UUID().uuidString)", isDirectory: true)
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
