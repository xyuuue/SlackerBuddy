import Foundation
import MacPetCore

let petStateMachineTests: [TestCase] = [
    TestCase(name: "pet state machine starts idle with no bubble") {
        let machine = PetStateMachine(now: { Date(timeIntervalSince1970: 0) })

        try expect(machine.state == .idle, "expected idle")
        try expect(machine.bubbleText == nil, "expected no bubble")
    },
    TestCase(name: "pet state machine falls asleep after inactivity") {
        var current = Date(timeIntervalSince1970: 0)
        let machine = PetStateMachine(now: { current })

        current = Date(timeIntervalSince1970: 31 * 60)
        machine.tick(preferences: PetPreferences(sleepDelayMinutes: 30))

        try expect(machine.state == .sleeping, "expected sleeping")
    },
    TestCase(name: "pet state machine wakes sleeping pet on interaction") {
        var current = Date(timeIntervalSince1970: 0)
        let machine = PetStateMachine(now: { current })

        current = Date(timeIntervalSince1970: 31 * 60)
        machine.tick(preferences: PetPreferences(sleepDelayMinutes: 30))
        machine.handle(.clicked)

        try expect(machine.state == .waking, "expected waking")
    },
    TestCase(name: "pet state machine pets awake pet on click") {
        let machine = PetStateMachine(now: { Date(timeIntervalSince1970: 0) })

        machine.handle(.clicked)

        try expect(machine.state == .petting, "expected petting")
    },
    TestCase(name: "pet state machine shows bubble on reminder") {
        let machine = PetStateMachine(now: { Date(timeIntervalSince1970: 0) })

        machine.handle(.reminderFired(.rest))

        try expect(machine.state == .reminding, "expected reminding")
        try expect(machine.bubbleText == "休息一下吧", "expected reminder bubble")
    },
    TestCase(name: "state machine shows water reminder bubble") {
        let machine = PetStateMachine(now: { Date(timeIntervalSince1970: 0) })

        machine.handle(.reminderFired(.water))

        try expect(machine.state == .reminding, "Expected water reminder to use reminding state")
        try expect(machine.activeReminderKind == .water, "Expected active water reminder kind")
    },
    TestCase(name: "automatic action does not reset inactivity") {
        var current = Date(timeIntervalSince1970: 0)
        let machine = PetStateMachine(now: { current })

        current = Date(timeIntervalSince1970: 60)
        machine.handle(.automaticAction(.blink))
        current = Date(timeIntervalSince1970: 30 * 60)
        machine.tick(preferences: PetPreferences(sleepDelayMinutes: 30))

        try expect(machine.state == .sleeping, "Expected automatic action not to reset user inactivity")
    },
    TestCase(name: "pet state machine dismisses reminder") {
        let machine = PetStateMachine(now: { Date(timeIntervalSince1970: 0) })

        machine.handle(.reminderFired(.rest))
        machine.handle(.dismissedReminder)

        try expect(machine.state == .idle, "expected idle")
        try expect(machine.bubbleText == nil, "expected no bubble")
    },
    TestCase(name: "pet state machine completes transient animations") {
        let machine = PetStateMachine(now: { Date(timeIntervalSince1970: 0) })

        machine.handle(.clicked)
        machine.handle(.animationCompleted)
        try expect(machine.state == .idle, "expected idle after petting animation")

        machine.handle(.reminderFired(.rest))
        machine.handle(.animationCompleted)
        try expect(machine.state == .reminding, "expected reminder to stay visible")
        try expect(machine.bubbleText == "休息一下吧", "expected reminder bubble to stay visible")
    },
    TestCase(name: "pet state machine resets sleep timer after interaction") {
        var current = Date(timeIntervalSince1970: 0)
        let machine = PetStateMachine(now: { current })
        let preferences = PetPreferences(sleepDelayMinutes: 30)

        current = Date(timeIntervalSince1970: 31 * 60)
        machine.tick(preferences: preferences)
        try expect(machine.state == .sleeping, "expected sleeping after initial inactivity")

        machine.handle(.clicked)
        try expect(machine.state == .waking, "expected waking after click")

        machine.handle(.animationCompleted)
        try expect(machine.state == .idle, "expected idle after waking animation")

        current = Date(timeIntervalSince1970: 40 * 60)
        machine.tick(preferences: preferences)
        try expect(machine.state == .idle, "expected idle before next sleep threshold")

        current = Date(timeIntervalSince1970: 62 * 60)
        machine.tick(preferences: preferences)
        try expect(machine.state == .sleeping, "expected sleeping after renewed inactivity")
    },
    TestCase(name: "pet state machine preserves reminder while inactive") {
        var current = Date(timeIntervalSince1970: 0)
        let machine = PetStateMachine(now: { current })

        machine.handle(.reminderFired(.rest))
        current = Date(timeIntervalSince1970: 120 * 60)
        machine.tick(preferences: PetPreferences(sleepDelayMinutes: 30))

        try expect(machine.state == .reminding, "expected reminder to stay visible after inactivity")
        try expect(machine.bubbleText == "休息一下吧", "expected reminder bubble to stay visible after inactivity")
    }
]
