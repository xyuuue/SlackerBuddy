import Foundation

@MainActor
public final class IntervalScheduler {
    public private(set) var isActive = false

    private var isEnabled = false
    private var intervalMinutes = 1
    private var nextFireAt: Date?
    private var onFire: (() -> Void)?
    private let now: () -> Date

    public init(now: @escaping () -> Date = Date.init) {
        self.now = now
    }

    public func start(intervalMinutes: Int, isEnabled: Bool, onFire: @escaping () -> Void) {
        self.intervalMinutes = max(1, intervalMinutes)
        self.isEnabled = isEnabled
        self.onFire = onFire
        isActive = false
        scheduleNext(from: now())
    }

    public func update(intervalMinutes: Int, isEnabled: Bool) {
        self.intervalMinutes = max(1, intervalMinutes)
        self.isEnabled = isEnabled
        isActive = false
        scheduleNext(from: now())
    }

    public func tick() {
        guard isEnabled, !isActive, let nextFireAt, now() >= nextFireAt else {
            return
        }

        isActive = true
        onFire?()
    }

    public func dismissActive() {
        isActive = false
        scheduleNext(from: now())
    }

    public func stop() {
        isEnabled = false
        isActive = false
        nextFireAt = nil
    }

    private func scheduleNext(from date: Date) {
        nextFireAt = isEnabled ? date.addingTimeInterval(TimeInterval(intervalMinutes * 60)) : nil
    }
}
