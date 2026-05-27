import AppKit

private enum PetAction: Equatable {
    case idle
    case blink
    case inspect
    case jump
    case fail
    case wait
    case runLeft
    case runRight
}

private final class PetView: NSView {
    var action: PetAction = .idle {
        didSet { needsDisplay = true }
    }
    var message: String? {
        didSet { needsDisplay = true }
    }
    var onDismissReminder: (() -> Void)?
    var onDragStarted: (() -> Void)?
    var onDragged: (() -> Void)?

    private var bubbleButtonRect: NSRect = .zero

    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.clear.setFill()
        dirtyRect.fill()

        let catRect = NSRect(x: 16, y: bounds.height - 132, width: 128, height: 118)
        drawCat(in: catRect)

        if let message = message {
            drawBubble(message, above: catRect)
        }
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        if bubbleButtonRect.contains(point) {
            onDismissReminder?()
            return
        }

        let clickAction = PetAction.randomClickAction()
        action = clickAction
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            if self?.action == clickAction {
                self?.action = .idle
            }
        }
        onDragStarted?()
    }

    override func mouseDragged(with event: NSEvent) {
        onDragged?()
    }

    private func drawBubble(_ text: String, above catRect: NSRect) {
        let bubbleRect = NSRect(x: 4, y: 4, width: bounds.width - 8, height: 64)
        let path = NSBezierPath(roundedRect: bubbleRect, xRadius: 12, yRadius: 12)
        NSColor(calibratedWhite: 1.0, alpha: 0.94).setFill()
        path.fill()
        NSColor(calibratedWhite: 0.18, alpha: 0.16).setStroke()
        path.lineWidth = 1
        path.stroke()

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13, weight: .medium),
            .foregroundColor: NSColor(calibratedWhite: 0.08, alpha: 1),
            .paragraphStyle: paragraph
        ]
        NSString(string: text).draw(in: NSRect(x: 12, y: 10, width: bubbleRect.width - 24, height: 18), withAttributes: textAttributes)

        bubbleButtonRect = NSRect(x: 38, y: 34, width: bubbleRect.width - 76, height: 22)
        let buttonPath = NSBezierPath(roundedRect: bubbleButtonRect, xRadius: 9, yRadius: 9)
        NSColor(calibratedRed: 0.16, green: 0.31, blue: 0.88, alpha: 1).setFill()
        buttonPath.fill()

        let buttonAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12, weight: .semibold),
            .foregroundColor: NSColor.white,
            .paragraphStyle: paragraph
        ]
        NSString(string: "I'm back!").draw(in: NSRect(x: bubbleButtonRect.minX, y: bubbleButtonRect.minY + 3, width: bubbleButtonRect.width, height: 16), withAttributes: buttonAttributes)
    }

    private func drawCat(in rect: NSRect) {
        NSGraphicsContext.saveGraphicsState()
        defer { NSGraphicsContext.restoreGraphicsState() }

        if action == .runLeft {
            let transform = NSAffineTransform()
            transform.translateX(by: rect.midX, yBy: 0)
            transform.scaleX(by: -1, yBy: 1)
            transform.translateX(by: -rect.midX, yBy: 0)
            transform.concat()
        }

        let jumpOffset: CGFloat = action == .jump ? -16 : 0
        let lean: CGFloat = (action == .runLeft || action == .runRight) ? 9 : 0
        let sadOffset: CGFloat = action == .fail ? 10 : 0

        let bodyRect = NSRect(x: rect.midX - 42 + lean, y: rect.minY + 44 + jumpOffset, width: 84, height: 62)
        let body = NSBezierPath(ovalIn: bodyRect)
        NSColor(calibratedRed: 0.98, green: 0.86, blue: 0.61, alpha: 1).setFill()
        body.fill()

        let headRect = NSRect(x: rect.midX - 38 + lean, y: rect.minY + 10 + jumpOffset + sadOffset, width: 76, height: 70)
        let head = NSBezierPath(ovalIn: headRect)
        NSColor(calibratedRed: 1.0, green: 0.88, blue: 0.64, alpha: 1).setFill()
        head.fill()

        drawEar(at: NSPoint(x: headRect.minX + 12, y: headRect.minY + 10), flipped: false)
        drawEar(at: NSPoint(x: headRect.maxX - 12, y: headRect.minY + 10), flipped: true)

        let mask = NSBezierPath(ovalIn: NSRect(x: headRect.midX - 24, y: headRect.midY - 16, width: 48, height: 38))
        NSColor(calibratedRed: 0.34, green: 0.22, blue: 0.15, alpha: 0.95).setFill()
        mask.fill()

        if action == .blink {
            drawClosedEye(x: headRect.midX - 16, y: headRect.midY - 2)
            drawClosedEye(x: headRect.midX + 16, y: headRect.midY - 2)
        } else {
            drawEye(x: headRect.midX - 16, y: headRect.midY - 6, inspecting: action == .inspect)
            drawEye(x: headRect.midX + 16, y: headRect.midY - 6, inspecting: action == .inspect)
        }

        let nose = NSBezierPath(ovalIn: NSRect(x: headRect.midX - 4, y: headRect.midY + 11, width: 8, height: 6))
        NSColor(calibratedRed: 0.13, green: 0.09, blue: 0.08, alpha: 1).setFill()
        nose.fill()

        drawLegs(in: bodyRect, jumping: action == .jump, running: action == .runLeft || action == .runRight)
        drawTail(from: bodyRect, waving: action == .wait || action == .runLeft || action == .runRight)
    }

    private func drawEar(at point: NSPoint, flipped: Bool) {
        let ear = NSBezierPath()
        ear.move(to: NSPoint(x: point.x, y: point.y - 24))
        ear.line(to: NSPoint(x: point.x + (flipped ? 18 : -18), y: point.y + 10))
        ear.line(to: NSPoint(x: point.x + (flipped ? -6 : 6), y: point.y + 5))
        ear.close()
        NSColor(calibratedRed: 0.31, green: 0.20, blue: 0.15, alpha: 1).setFill()
        ear.fill()
        NSColor(calibratedRed: 0.95, green: 0.55, blue: 0.52, alpha: 1).setFill()
        ear.lineWidth = 2
    }

    private func drawEye(x: CGFloat, y: CGFloat, inspecting: Bool) {
        let eye = NSBezierPath(ovalIn: NSRect(x: x - 7, y: y - 9, width: 14, height: 18))
        NSColor(calibratedRed: 0.03, green: 0.09, blue: 0.12, alpha: 1).setFill()
        eye.fill()
        let irisOffset: CGFloat = inspecting ? 3 : 0
        let iris = NSBezierPath(ovalIn: NSRect(x: x - 4 + irisOffset, y: y - 5, width: 8, height: 11))
        NSColor(calibratedRed: 0.20, green: 0.68, blue: 0.95, alpha: 1).setFill()
        iris.fill()
        NSColor.white.setFill()
        NSBezierPath(ovalIn: NSRect(x: x - 2 + irisOffset, y: y - 4, width: 3, height: 3)).fill()
    }

    private func drawClosedEye(x: CGFloat, y: CGFloat) {
        let path = NSBezierPath()
        path.move(to: NSPoint(x: x - 8, y: y))
        path.curve(to: NSPoint(x: x + 8, y: y), controlPoint1: NSPoint(x: x - 4, y: y + 5), controlPoint2: NSPoint(x: x + 4, y: y + 5))
        NSColor(calibratedRed: 0.08, green: 0.05, blue: 0.04, alpha: 1).setStroke()
        path.lineWidth = 2
        path.stroke()
    }

    private func drawLegs(in body: NSRect, jumping: Bool, running: Bool) {
        let offset: CGFloat = jumping ? 8 : 0
        for index in 0..<4 {
            let stride = running && index % 2 == 0 ? CGFloat(-7) : CGFloat(4)
            let legRect = NSRect(x: body.minX + 14 + CGFloat(index) * 16 + stride, y: body.maxY - 12 + offset, width: 12, height: 28)
            let leg = NSBezierPath(roundedRect: legRect, xRadius: 5, yRadius: 5)
            NSColor(calibratedRed: 0.28, green: 0.20, blue: 0.17, alpha: 1).setFill()
            leg.fill()
        }
    }

    private func drawTail(from body: NSRect, waving: Bool) {
        let tail = NSBezierPath()
        tail.move(to: NSPoint(x: body.maxX - 6, y: body.midY))
        tail.curve(
            to: NSPoint(x: body.maxX + 28, y: body.midY - (waving ? 28 : 16)),
            controlPoint1: NSPoint(x: body.maxX + 26, y: body.midY + 2),
            controlPoint2: NSPoint(x: body.maxX + 30, y: body.midY - 28)
        )
        NSColor(calibratedRed: 0.29, green: 0.21, blue: 0.18, alpha: 1).setStroke()
        tail.lineWidth = 12
        tail.lineCapStyle = .round
        tail.stroke()
    }
}

private extension PetAction {
    static func randomClickAction() -> PetAction {
        let actions: [PetAction] = [.inspect, .jump, .fail, .wait, .runLeft, .runRight]
        return actions[Int(arc4random_uniform(UInt32(actions.count)))]
    }
}

private final class PetWindowController: NSObject {
    private let window: NSWindow
    private let petView = PetView(frame: NSRect(x: 0, y: 0, width: 172, height: 154))
    private var blinkTimer: Timer?
    private var resetActionTimer: Timer?
    private var reminderTimer: Timer?
    private var dragStartFrame: NSRect = .zero
    private var dragStartPoint: NSPoint = .zero
    private var reminderEnabled = true

    override init() {
        window = NSWindow(
            contentRect: NSRect(x: 120, y: 120, width: 172, height: 154),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        super.init()

        window.title = "SlackerBuddy"
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.hasShadow = false
        window.contentView = petView

        petView.onDismissReminder = { [weak self] in
            self?.dismissReminder()
        }
        petView.onDragStarted = { [weak self] in
            self?.startDragging()
        }
        petView.onDragged = { [weak self] in
            self?.continueDragging()
        }
    }

    func show() {
        positionIfNeeded()
        window.orderFrontRegardless()
        startBlinking()
        startReminderTimer()
    }

    func hide() {
        window.orderOut(nil)
    }

    func toggleReminder(_ enabled: Bool) {
        reminderEnabled = enabled
        startReminderTimer()
    }

    func startDragging() {
        dragStartFrame = window.frame
        dragStartPoint = NSEvent.mouseLocation
    }

    func continueDragging() {
        let current = NSEvent.mouseLocation
        let dx = current.x - dragStartPoint.x
        let dy = current.y - dragStartPoint.y
        var frame = dragStartFrame
        frame.origin.x += dx
        frame.origin.y += dy
        window.setFrame(frame, display: true)
        if abs(dx) > 1 {
            petView.action = dx < 0 ? .runLeft : .runRight
        }
        scheduleActionReset(after: 0.8)
    }

    private func positionIfNeeded() {
        guard let screen = NSScreen.main else { return }
        let visible = screen.visibleFrame
        var frame = window.frame
        if !visible.intersects(frame) {
            frame.origin = NSPoint(x: visible.maxX - frame.width - 32, y: visible.minY + 32)
            window.setFrame(frame, display: false)
        }
    }

    private func startBlinking() {
        blinkTimer?.invalidate()
        blinkTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { [weak self] _ in
            self?.blink()
        }
    }

    private func blink() {
        guard petView.action == .idle else { return }
        petView.action = .blink
        scheduleActionReset(after: 0.18)
    }

    private func scheduleActionReset(after delay: TimeInterval) {
        resetActionTimer?.invalidate()
        resetActionTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.petView.action = .idle
        }
    }

    private func startReminderTimer() {
        reminderTimer?.invalidate()
        guard reminderEnabled else { return }
        reminderTimer = Timer.scheduledTimer(withTimeInterval: 25 * 60, repeats: true) { [weak self] _ in
            self?.showReminder()
        }
    }

    private func showReminder() {
        petView.message = "Time for a break"
        petView.action = .wait
        scheduleActionReset(after: 3.0)
    }

    private func dismissReminder() {
        petView.message = nil
        petView.action = .idle
        startReminderTimer()
    }
}

private final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private let petController = PetWindowController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configureMenuBar()
        petController.show()
    }

    private func configureMenuBar() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "SB"

        let menu = NSMenu()
        menu.addItem(makeMenuItem(title: "Show Pet", action: #selector(showPet), keyEquivalent: "s"))
        menu.addItem(makeMenuItem(title: "Hide Pet", action: #selector(hidePet), keyEquivalent: "h"))
        let reminderItem = makeMenuItem(title: "Rest Reminder", action: #selector(toggleReminder(_:)), keyEquivalent: "r")
        reminderItem.state = .on
        menu.addItem(reminderItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(makeMenuItem(title: "Quit SlackerBuddy", action: #selector(quit), keyEquivalent: "q"))
        item.menu = menu
        statusItem = item
    }

    private func makeMenuItem(title: String, action: Selector, keyEquivalent: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
        item.target = self
        return item
    }

    @objc private func showPet() {
        petController.show()
    }

    @objc private func hidePet() {
        petController.hide()
    }

    @objc private func toggleReminder(_ sender: NSMenuItem) {
        sender.state = sender.state == .on ? .off : .on
        petController.toggleReminder(sender.state == .on)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

private final class LegacyApplication {
    private static let applicationDelegate = AppDelegate()

    static func run() {
        let application = NSApplication.shared
        application.delegate = applicationDelegate
        application.run()
    }
}

LegacyApplication.run()
