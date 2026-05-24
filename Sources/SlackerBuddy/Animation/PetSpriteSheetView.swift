import AppKit
import SwiftUI
import SlackerBuddyCore

public struct PetSpriteSheetView: View {
    private let spriteSheetURL: URL
    private let state: PetState
    private let frameName: String

    public init(spriteSheetURL: URL, state: PetState, frameName: String) {
        self.spriteSheetURL = spriteSheetURL
        self.state = state
        self.frameName = frameName
    }

    public var body: some View {
        if let image = PetSpriteSheetFrameCache.shared.frame(
            spriteSheetURL: spriteSheetURL,
            row: SpriteFrameMapping.row(for: state),
            column: frameColumn
        ) {
            Image(nsImage: image)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .accessibilityLabel("Petdex pet")
        } else {
            PixelCatPlaceholderView(frameName: frameName)
        }
    }

    private var frameColumn: Int {
        guard let suffix = frameName.split(separator: "-").last,
              let index = Int(suffix) else {
            return 0
        }

        return index
    }
}

@MainActor
final class PetSpriteSheetFrameCache {
    static let shared = PetSpriteSheetFrameCache()

    private let columns = 8
    private let rows = 9

    private var cachedURL: URL?
    private var cachedAtlas: CGImage?
    private var cachedFrames: [String: NSImage] = [:]

    private init() {}

    func frame(spriteSheetURL: URL, row: Int, column: Int) -> NSImage? {
        if cachedURL != spriteSheetURL {
            cachedURL = spriteSheetURL
            cachedAtlas = Self.loadAtlas(from: spriteSheetURL)
            cachedFrames.removeAll()
        }

        let safeRow = min(max(row, 0), rows - 1)
        let safeColumn = min(max(column, 0), columns - 1)
        let cacheKey = "\(safeRow)-\(safeColumn)"

        if let cachedFrame = cachedFrames[cacheKey] {
            return cachedFrame
        }

        guard let frame = croppedFrame(spriteSheetURL: spriteSheetURL, row: safeRow, column: safeColumn) else {
            return nil
        }

        cachedFrames[cacheKey] = frame
        return frame
    }

    private func croppedFrame(spriteSheetURL: URL, row: Int, column: Int) -> NSImage? {
        guard let cgImage = cachedAtlas else {
            return nil
        }

        let frameWidth = cgImage.width / columns
        let frameHeight = cgImage.height / rows
        guard frameWidth > 0, frameHeight > 0 else {
            return nil
        }

        let cropRect = CGRect(
            x: column * frameWidth,
            y: row * frameHeight,
            width: frameWidth,
            height: frameHeight
        )

        guard let frame = cgImage.cropping(to: cropRect) else {
            return nil
        }

        return NSImage(cgImage: frame, size: NSSize(width: frameWidth, height: frameHeight))
    }

    private static func loadAtlas(from url: URL) -> CGImage? {
        guard
            let atlas = NSImage(contentsOf: url),
            let cgImage = atlas.cgImage(forProposedRect: nil, context: nil, hints: nil)
        else {
            return nil
        }

        return cgImage
    }
}
