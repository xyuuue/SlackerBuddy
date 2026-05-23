import Foundation

@MainActor
public final class ReminderScheduler {
    public var onReminder: (() -> Void)?
    public private(set) var isReminderActive = false

    private var intervalMinutes: Int = 25
    private var nextReminderAt: Date?
    private let now: () -> Date

    public init(now: @escaping () -> Date = Date.init) {
        self.now = now
    }

    public func start(intervalMinutes: Int) {
        self.intervalMinutes = max(1, intervalMinutes)
        isReminderActive = false
        scheduleNext(from: now())
    }

    public func updateInterval(minutes: Int) {
        intervalMinutes = max(1, minutes)
        isReminderActive = false
        scheduleNext(from: now())
    }

    public func tick() {
        guard !isReminderActive, let nextReminderAt else {
            return
        }

        guard now() >= nextReminderAt else {
            return
        }

        isReminderActive = true
        onReminder?()
    }

    public func dismissActiveReminder() {
        isReminderActive = false
        scheduleNext(from: now())
    }

    private func scheduleNext(from date: Date) {
        nextReminderAt = date.addingTimeInterval(TimeInterval(intervalMinutes * 60))
    }
}
