import SwiftUI

public struct BubbleView: View {
    let text: String
    let buttonTitle: String?
    let onDismiss: () -> Void

    public init(text: String, buttonTitle: String? = nil, onDismiss: @escaping () -> Void) {
        self.text = text
        self.buttonTitle = buttonTitle
        self.onDismiss = onDismiss
    }

    public var body: some View {
        VStack(spacing: 8) {
            Text(text)
                .font(.callout.weight(.medium))
                .lineLimit(2)
                .multilineTextAlignment(.center)

            if let buttonTitle {
                Button(action: onDismiss) {
                    Text(buttonTitle)
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.primary.opacity(0.1), in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .foregroundStyle(.primary)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.quaternary, lineWidth: 1)
        }
        .accessibilityLabel("Dismiss reminder: \(text)")
    }
}
