import Foundation
import SlackerBuddyCore

let intervalSchedulerTests: [TestCase] = [
    TestCase(name: "disabled scheduler does not fire") {
        var current = Date(timeIntervalSince1970: 0)
        let scheduler = IntervalScheduler(now: { current })
        var fired = false
        scheduler.start(intervalMinutes: 1, isEnabled: false) { fired = true }
        current = Date(timeIntervalSince1970: 61)
        scheduler.tick()
        try expect(!fired, "Expected disabled scheduler not to fire")
    },
    TestCase(name: "enabled scheduler fires once and stays active") {
        var current = Date(timeIntervalSince1970: 0)
        let scheduler = IntervalScheduler(now: { current })
        var fireCount = 0
        scheduler.start(intervalMinutes: 1, isEnabled: true) { fireCount += 1 }
        current = Date(timeIntervalSince1970: 61)
        scheduler.tick()
        scheduler.tick()
        try expect(fireCount == 1, "Expected active scheduler to fire once")
        try expect(scheduler.isActive == true, "Expected scheduler to remain active until dismissed")
    },
    TestCase(name: "dismiss schedules next interval") {
        var current = Date(timeIntervalSince1970: 0)
        let scheduler = IntervalScheduler(now: { current })
        var fireCount = 0
        scheduler.start(intervalMinutes: 1, isEnabled: true) { fireCount += 1 }
        current = Date(timeIntervalSince1970: 61)
        scheduler.tick()
        scheduler.dismissActive()
        current = Date(timeIntervalSince1970: 122)
        scheduler.tick()
        try expect(fireCount == 2, "Expected dismiss to schedule next reminder")
    }
]
