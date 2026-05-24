import AppKit
import SwiftUI
import MacPetCore

public struct PetSpriteSheetView: View {
    private static let columns = 8
    private static let rows = 9

    private let spriteSheetURL: URL
    private let state: PetState
    private let frameName: String

    public init(spriteSheetURL: URL, state: PetState, frameName: String) {
        self.spriteSheetURL = spriteSheetURL
        self.state = state
        self.frameName = frameName
    }

    public var body: some View {
        if let image = croppedFrameImage() {
            Image(nsImage: image)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .accessibilityLabel("Petdex pet")
        } else {
            PixelCatPlaceholderView(frameName: frameName)
        }
    }

    private func croppedFrameImage() -> NSImage? {
        guard
            let atlas = NSImage(contentsOf: spriteSheetURL),
            let cgImage = atlas.cgImage(forProposedRect: nil, context: nil, hints: nil)
        else {
            return nil
        }

        let frameWidth = cgImage.width / Self.columns
        let frameHeight = cgImage.height / Self.rows
        guard frameWidth > 0, frameHeight > 0 else {
            return nil
        }

        let row = min(max(SpriteFrameMapping.row(for: state), 0), Self.rows - 1)
        let column = min(max(frameColumn, 0), Self.columns - 1)
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

    private var frameColumn: Int {
        guard let suffix = frameName.split(separator: "-").last,
              let index = Int(suffix) else {
            return 0
        }

        return index
    }
}
