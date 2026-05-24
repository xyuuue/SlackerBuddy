import Foundation

public struct PetdexCatalog: Sendable {
    public let rootDirectory: URL

    public init(rootDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".codex", isDirectory: true)
        .appendingPathComponent("pets", isDirectory: true)) {
        self.rootDirectory = rootDirectory
    }

    public func loadPets() -> [PetAsset] {
        let petDirectories = (try? FileManager.default.contentsOfDirectory(
            at: rootDirectory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )) ?? []

        let pets = petDirectories
            .filter { $0.isDirectory }
            .compactMap(loadPet)
            .sorted { lhs, rhs in
                lhs.displayName.localizedStandardCompare(rhs.displayName) == .orderedAscending
            }

        return [PetAsset.builtin] + pets
    }

    private func loadPet(from packageDirectory: URL) -> PetAsset? {
        let metadataURL = packageDirectory.appendingPathComponent("pet.json")

        guard
            let data = try? Data(contentsOf: metadataURL),
            let metadata = try? JSONDecoder().decode(PetPackageMetadata.self, from: data)
        else {
            return nil
        }

        let spriteSheetURL = packageDirectory.appendingPathComponent(metadata.spritesheetPath)
        guard FileManager.default.fileExists(atPath: spriteSheetURL.path) else {
            return nil
        }

        return PetAsset(
            id: metadata.id,
            displayName: metadata.displayName,
            description: metadata.description,
            spriteSheetURL: spriteSheetURL
        )
    }
}

private struct PetPackageMetadata: Decodable {
    let id: String
    let displayName: String
    let description: String
    let spritesheetPath: String
}

private extension URL {
    var isDirectory: Bool {
        (try? resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
    }
}
