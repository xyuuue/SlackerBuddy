import Foundation

public struct PetAsset: Identifiable, Equatable, Sendable {
    public static let builtinID = "fufu"
    public static let builtin = PetAsset(
        id: builtinID,
        displayName: "FuFu",
        description: "Built-in pixel-art Siamese kitten",
        spriteSheetURL: nil
    )

    public let id: String
    public let displayName: String
    public let description: String
    public let spriteSheetURL: URL?

    public var isBuiltin: Bool {
        id == Self.builtinID
    }

    public init(id: String, displayName: String, description: String, spriteSheetURL: URL?) {
        self.id = id
        self.displayName = displayName
        self.description = description
        self.spriteSheetURL = spriteSheetURL
    }
}
