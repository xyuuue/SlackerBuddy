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

        machine.handle(.reminderFired)

        try expect(machine.state == .reminding, "expected reminding")
        try expect(machine.bubbleText == "休息一下吧", "expected reminder bubble")
    },
    TestCase(name: "pet state machine dismisses reminder") {
        let machine = PetStateMachine(now: { Date(timeIntervalSince1970: 0) })

        machine.handle(.reminderFired)
        machine.handle(.dismissedReminder)

        try expect(machine.state == .idle, "expected idle")
        try expect(machine.bubbleText == nil, "expected no bubble")
    },
    TestCase(name: "pet state machine completes transient animations") {
        let machine = PetStateMachine(now: { Date(timeIntervalSince1970: 0) })

        machine.handle(.clicked)
        machine.handle(.animationCompleted)
        try expect(machine.state == .idle, "expected idle after petting animation")

        machine.handle(.reminderFired)
        machine.handle(.animationCompleted)
        try expect(machine.state == .reminding, "expected reminder to stay visible")
        try expect(machine.bubbleText == "休息一下吧", "expected reminder bubble to stay visible")
    }
]
