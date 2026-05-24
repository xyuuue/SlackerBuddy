import Foundation
import MacPetCore

let reminderSchedulerTests: [TestCase] = [
    TestCase(name: "reminder scheduler does not fire before interval") {
        var current = Date(timeIntervalSince1970: 0)
        var firedCount = 0
        let scheduler = ReminderScheduler(now: { current })
        scheduler.onReminder = {
            firedCount += 1
        }

        scheduler.start(intervalMinutes: 25)
        current = Date(timeIntervalSince1970: 24 * 60)
        scheduler.tick()

        try expect(firedCount == 0, "expected reminder not to fire before interval")
        try expect(scheduler.isReminderActive == false, "expected reminder to remain inactive")
    },
    TestCase(name: "reminder scheduler fires at custom interval") {
        var current = Date(timeIntervalSince1970: 0)
        var firedCount = 0
        let scheduler = ReminderScheduler(now: { current })
        scheduler.onReminder = {
            firedCount += 1
        }

        scheduler.start(intervalMinutes: 45)
        current = Date(timeIntervalSince1970: 45 * 60)
        scheduler.tick()

        try expect(firedCount == 1, "expected reminder to fire at custom interval")
        try expect(scheduler.isReminderActive == true, "expected reminder to become active")
    },
    TestCase(name: "reminder scheduler dismiss restarts timer") {
        var current = Date(timeIntervalSince1970: 0)
        var firedCount = 0
        let scheduler = ReminderScheduler(now: { current })
        scheduler.onReminder = {
            firedCount += 1
        }

        scheduler.start(intervalMinutes: 10)
        current = Date(timeIntervalSince1970: 10 * 60)
        scheduler.tick()
        scheduler.dismissActiveReminder()

        current = Date(timeIntervalSince1970: 19 * 60)
        scheduler.tick()
        try expect(firedCount == 1, "expected no second reminder before restarted interval")

        current = Date(timeIntervalSince1970: 20 * 60)
        scheduler.tick()
        try expect(firedCount == 2, "expected second reminder after restarted interval")
    },
    TestCase(name: "reminder scheduler updating interval restarts from now") {
        var current = Date(timeIntervalSince1970: 0)
        var firedCount = 0
        let scheduler = ReminderScheduler(now: { current })
        scheduler.onReminder = {
            firedCount += 1
        }

        scheduler.start(intervalMinutes: 25)
        current = Date(timeIntervalSince1970: 20 * 60)
        scheduler.updateInterval(minutes: 5)

        current = Date(timeIntervalSince1970: 24 * 60)
        scheduler.tick()
        try expect(firedCount == 0, "expected no reminder before updated interval")

        current = Date(timeIntervalSince1970: 25 * 60)
        scheduler.tick()
        try expect(firedCount == 1, "expected reminder at updated interval")
    },
    TestCase(name: "reminder scheduler clamps invalid interval") {
        var current = Date(timeIntervalSince1970: 0)
        var firedCount = 0
        let scheduler = ReminderScheduler(now: { current })
        scheduler.onReminder = {
            firedCount += 1
        }

        scheduler.start(intervalMinutes: 0)
        current = Date(timeIntervalSince1970: 59)
        scheduler.tick()
        try expect(firedCount == 0, "expected no reminder before clamped interval")

        current = Date(timeIntervalSince1970: 60)
        scheduler.tick()
        try expect(firedCount == 1, "expected reminder after clamped interval")
    },
    TestCase(name: "reminder scheduler while active does not fire repeatedly") {
        var current = Date(timeIntervalSince1970: 0)
        var firedCount = 0
        let scheduler = ReminderScheduler(now: { current })
        scheduler.onReminder = {
            firedCount += 1
        }

        scheduler.start(intervalMinutes: 5)
        current = Date(timeIntervalSince1970: 5 * 60)
        scheduler.tick()

        current = Date(timeIntervalSince1970: 6 * 60)
        scheduler.tick()
        scheduler.tick()
        scheduler.tick()

        try expect(firedCount == 1, "expected active reminder not to fire repeatedly")
    },
    TestCase(name: "reminder scheduler stop prevents future fire") {
        var current = Date(timeIntervalSince1970: 0)
        var firedCount = 0
        let scheduler = ReminderScheduler(now: { current })
        scheduler.onReminder = {
            firedCount += 1
        }

        scheduler.start(intervalMinutes: 1)
        scheduler.stop()
        current = Date(timeIntervalSince1970: 61)
        scheduler.tick()

        try expect(firedCount == 0, "expected stopped reminder scheduler not to fire")
        try expect(scheduler.isReminderActive == false, "expected stopped scheduler to clear active state")
    }
]
