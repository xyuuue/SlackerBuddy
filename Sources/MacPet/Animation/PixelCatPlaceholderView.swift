import SwiftUI

public struct PixelCatPlaceholderView: View {
    public let frameName: String

    public init(frameName: String) {
        self.frameName = frameName
    }

    public var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let unit = size / 16
            let tailSway = frameName.contains("tail-sway-1")

            ZStack {
                tail(unit: unit, isSwaying: tailSway)

                Rectangle()
                    .fill(Color(red: 0.89, green: 0.78, blue: 0.58))
                    .frame(width: unit * 8, height: unit * 6)
                    .position(x: unit * 8, y: unit * 10)

                Rectangle()
                    .fill(Color(red: 0.94, green: 0.84, blue: 0.64))
                    .frame(width: unit * 6, height: unit * 5)
                    .position(x: unit * 7.5, y: unit * 6.5)

                ears(unit: unit)
                face(unit: unit)
                paws(unit: unit)
            }
            .frame(width: size, height: size)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityLabel("Pixel Siamese cat")
    }

    private func tail(unit: CGFloat, isSwaying: Bool) -> some View {
        Rectangle()
            .fill(Color(red: 0.19, green: 0.13, blue: 0.12))
            .frame(width: unit * 2, height: unit * 7)
            .rotationEffect(.degrees(isSwaying ? 22 : -8), anchor: .bottom)
            .offset(x: isSwaying ? unit * 0.7 : 0, y: isSwaying ? -unit * 0.2 : 0)
            .position(x: unit * 12.5, y: unit * 8.5)
    }

    private func ears(unit: CGFloat) -> some View {
        ZStack {
            Triangle()
                .fill(Color(red: 0.19, green: 0.13, blue: 0.12))
                .frame(width: unit * 3, height: unit * 3)
                .position(x: unit * 5.5, y: unit * 3.5)

            Triangle()
                .fill(Color(red: 0.19, green: 0.13, blue: 0.12))
                .frame(width: unit * 3, height: unit * 3)
                .position(x: unit * 9.5, y: unit * 3.5)
        }
    }

    private func face(unit: CGFloat) -> some View {
        ZStack {
            Rectangle()
                .fill(Color(red: 0.24, green: 0.16, blue: 0.14))
                .frame(width: unit * 4, height: unit * 3)
                .position(x: unit * 7.5, y: unit * 6.8)

            Rectangle()
                .fill(Color(red: 0.32, green: 0.78, blue: 1.0))
                .frame(width: unit * 0.8, height: unit * 0.8)
                .position(x: unit * 6.4, y: unit * 6.2)

            Rectangle()
                .fill(Color(red: 0.32, green: 0.78, blue: 1.0))
                .frame(width: unit * 0.8, height: unit * 0.8)
                .position(x: unit * 8.6, y: unit * 6.2)

            Rectangle()
                .fill(Color(red: 0.08, green: 0.05, blue: 0.05))
                .frame(width: unit * 1.2, height: unit * 0.6)
                .position(x: unit * 7.5, y: unit * 7.6)
        }
    }

    private func paws(unit: CGFloat) -> some View {
        ZStack {
            Rectangle()
                .fill(Color(red: 0.19, green: 0.13, blue: 0.12))
                .frame(width: unit * 2, height: unit * 1.5)
                .position(x: unit * 5.5, y: unit * 12.2)

            Rectangle()
                .fill(Color(red: 0.19, green: 0.13, blue: 0.12))
                .frame(width: unit * 2, height: unit * 1.5)
                .position(x: unit * 10.5, y: unit * 12.2)
        }
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()

        return path
    }
}
