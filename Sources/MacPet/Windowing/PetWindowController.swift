import AppKit
import SwiftUI

@MainActor
public final class PetWindowController {
    public private(set) var window: NSWindow?
    public var onMoved: (() -> Void)?

    private let defaults: UserDefaults
    private let frameDefaultsKey: String
    private var observerTokens: [NSObjectProtocol] = []
    private var preBlockingFrame: NSRect?
    private var isBlockingOverlayActive = false
    private var isProgrammaticFrameChange = false

    public init(
        defaults: UserDefaults = .standard,
        frameDefaultsKey: String = "window.pet.frame"
    ) {
        self.defaults = defaults
        self.frameDefaultsKey = frameDefaultsKey
    }

    public func show<RootView: View>(rootView: RootView, scale: Double) {
        if let window {
            window.orderFrontRegardless()
            return
        }

        let frame = restoredFrame() ?? defaultFrame(scale: scale)
        let hostingView = NSHostingView(rootView: rootView)
        hostingView.frame = NSRect(origin: .zero, size: frame.size)

        let window = NSWindow(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.title = "Mac Pet"
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isMovableByWindowBackground = true
        window.acceptsMouseMovedEvents = true
        window.ignoresMouseEvents = false
        window.isReleasedWhenClosed = false
        window.contentView = hostingView

        self.window = window
        observe(window: window)
        window.orderFrontRegardless()
    }

    public func hide() {
        window?.orderOut(nil)
    }

    public func close() {
        guard let window else {
            return
        }

        saveFrame()
        window.close()
        removeObservers()
        self.window = nil
    }

    public func updateScale(_ scale: Double) {
        guard let window else {
            return
        }

        let size = Self.windowSize(scale: scale)
        var frame = window.frame
        frame.size = size
        window.setFrame(frame, display: true, animate: false)
        saveFrame()
    }

    public func presentBlockingOverlay(scalePercent: Int) {
        guard let window else {
            return
        }

        if !isBlockingOverlayActive {
            preBlockingFrame = window.frame
        }

        isBlockingOverlayActive = true
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        let clampedPercent = max(10, min(scalePercent, 90))
        let side = min(screenFrame.width, screenFrame.height) * CGFloat(clampedPercent) / 100
        let frame = NSRect(
            x: screenFrame.midX - side / 2,
            y: screenFrame.midY - side / 2,
            width: side,
            height: side
        )

        performProgrammaticFrameChange {
            window.setFrame(frame, display: true, animate: false)
        }
    }

    public func restoreFromBlockingOverlay(scale: Double) {
        guard let window, isBlockingOverlayActive else {
            return
        }

        let frame = preBlockingFrame ?? defaultFrame(scale: scale)
        performProgrammaticFrameChange {
            window.setFrame(frame, display: true, animate: false)
        }
        preBlockingFrame = nil
        isBlockingOverlayActive = false
    }

    public func resetPosition(scale: Double) {
        defaults.removeObject(forKey: frameDefaultsKey)
        let frame = defaultFrame(scale: scale)

        if let window {
            window.setFrame(frame, display: true, animate: false)
            saveFrame()
        }
    }

    public func saveFrame() {
        guard !isBlockingOverlayActive, !isProgrammaticFrameChange else {
            return
        }

        guard let window else {
            return
        }

        defaults.set(NSStringFromRect(window.frame), forKey: frameDefaultsKey)
    }

    private func observe(window: NSWindow) {
        removeObservers()

        let center = NotificationCenter.default
        observerTokens = [
            center.addObserver(
                forName: NSWindow.didMoveNotification,
                object: window,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    guard self?.isProgrammaticFrameChange == false else {
                        return
                    }

                    self?.saveFrame()
                    self?.onMoved?()
                }
            },
            center.addObserver(
                forName: NSWindow.didResizeNotification,
                object: window,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.saveFrame()
                }
            },
            center.addObserver(
                forName: NSWindow.willCloseNotification,
                object: window,
                queue: .main
            ) { [weak self] notification in
                Task { @MainActor in
                    self?.windowWillClose(notification)
                }
            }
        ]
    }

    private func windowWillClose(_ notification: Notification) {
        if let closingWindow = notification.object as? NSWindow,
           closingWindow === window {
            saveFrame()
            removeObservers()
            window = nil
        }
    }

    private func removeObservers() {
        let center = NotificationCenter.default
        observerTokens.forEach(center.removeObserver)
        observerTokens.removeAll()
    }

    private func performProgrammaticFrameChange(_ change: () -> Void) {
        isProgrammaticFrameChange = true
        change()
        DispatchQueue.main.async { [weak self] in
            Task { @MainActor in
                self?.isProgrammaticFrameChange = false
            }
        }
    }

    private func restoredFrame() -> NSRect? {
        guard let frameString = defaults.string(forKey: frameDefaultsKey) else {
            return nil
        }

        let frame = NSRectFromString(frameString)
        guard isValid(frame: frame) else {
            return nil
        }

        return frame
    }

    private func isValid(frame: NSRect) -> Bool {
        guard frame.width > 0, frame.height > 0, !frame.isNull, !frame.isEmpty else {
            return false
        }

        return NSScreen.screens.contains { screen in
            screen.visibleFrame.intersects(frame)
        }
    }

    private func defaultFrame(scale: Double) -> NSRect {
        let size = Self.windowSize(scale: scale)
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        let margin: CGFloat = 24
        let x = screenFrame.maxX - size.width - margin
        let y = screenFrame.minY + margin

        return NSRect(x: x, y: y, width: size.width, height: size.height)
    }

    private static func windowSize(scale: Double) -> NSSize {
        let side = 176 * max(0.5, min(scale, 3.0))
        return NSSize(width: side, height: side + 48)
    }
}
