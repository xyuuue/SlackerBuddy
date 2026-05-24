import Foundation

@MainActor
public final class ReminderScheduler {
    public var onReminder: (() -> Void)?
    public var isReminderActive: Bool {
        scheduler.isActive
    }

    public var isActive: Bool {
        scheduler.isActive
    }

    private let scheduler: IntervalScheduler

    public init(now: @escaping () -> Date = Date.init) {
        scheduler = IntervalScheduler(now: now)
    }

    public func start(intervalMinutes: Int) {
        scheduler.start(intervalMinutes: intervalMinutes, isEnabled: true) { [weak self] in
            self?.onReminder?()
        }
    }

    public func updateInterval(minutes: Int) {
        scheduler.update(intervalMinutes: minutes, isEnabled: true)
    }

    public func stop() {
        scheduler.stop()
    }

    public func tick() {
        scheduler.tick()
    }

    public func dismissActiveReminder() {
        scheduler.dismissActive()
    }
}
