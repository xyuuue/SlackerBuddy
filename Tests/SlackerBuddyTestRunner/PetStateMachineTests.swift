import Foundation
import SlackerBuddyCore

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
        machine.tick()

        try expect(machine.state == .sleeping, "expected sleeping")
    },
    TestCase(name: "pet state machine wakes sleeping pet on interaction") {
        var current = Date(timeIntervalSince1970: 0)
        let machine = PetStateMachine(now: { current })

        current = Date(timeIntervalSince1970: 31 * 60)
        machine.tick()
        machine.handle(.clicked)

        try expect(machine.state == .waking, "expected waking")
    },
    TestCase(name: "pet state machine can play expressive click actions") {
        let machine = PetStateMachine(now: { Date(timeIntervalSince1970: 0) })

        machine.handle(.expressiveAction(.review))
        try expect(machine.state == .reviewing, "expected review action")

        machine.handle(.animationCompleted)
        machine.handle(.expressiveAction(.jump))
        try expect(machine.state == .jumping, "expected jump action")

        machine.handle(.animationCompleted)
        machine.handle(.expressiveAction(.fail))
        try expect(machine.state == .failed, "expected fail action")

        machine.handle(.animationCompleted)
        machine.handle(.expressiveAction(.wait))
        try expect(machine.state == .waiting, "expected wait action")

        machine.handle(.animationCompleted)
        machine.handle(.expressiveAction(.run))
        try expect(machine.state == .running, "expected run action")
    },
    TestCase(name: "pet state machine shows bubble on reminder") {
        let machine = PetStateMachine(now: { Date(timeIntervalSince1970: 0) })

        machine.handle(.reminderFired(.rest))

        try expect(machine.state == .waving, "expected waving reminder feedback")
        try expect(machine.bubbleText == "休息一下吧", "expected reminder bubble")
    },
    TestCase(name: "state machine shows water reminder bubble") {
        let machine = PetStateMachine(now: { Date(timeIntervalSince1970: 0) })

        machine.handle(.reminderFired(.water))

        try expect(machine.state == .waving, "Expected water reminder to wave first")
        try expect(machine.activeReminderKind == .water, "Expected active water reminder kind")
    },
    TestCase(name: "automatic action does not reset inactivity") {
        var current = Date(timeIntervalSince1970: 0)
        let machine = PetStateMachine(now: { current })

        current = Date(timeIntervalSince1970: 60)
        machine.handle(.automaticAction(.blink))
        current = Date(timeIntervalSince1970: 30 * 60)
        machine.tick()

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

        current = Date(timeIntervalSince1970: 31 * 60)
        machine.tick()
        try expect(machine.state == .sleeping, "expected sleeping after initial inactivity")

        machine.handle(.clicked)
        try expect(machine.state == .waking, "expected waking after click")

        machine.handle(.animationCompleted)
        try expect(machine.state == .idle, "expected idle after waking animation")

        current = Date(timeIntervalSince1970: 40 * 60)
        machine.tick()
        try expect(machine.state == .idle, "expected idle before next sleep threshold")

        current = Date(timeIntervalSince1970: 62 * 60)
        machine.tick()
        try expect(machine.state == .sleeping, "expected sleeping after renewed inactivity")
    },
    TestCase(name: "pet state machine preserves reminder while inactive") {
        var current = Date(timeIntervalSince1970: 0)
        let machine = PetStateMachine(now: { current })

        machine.handle(.reminderFired(.rest))
        machine.handle(.animationCompleted)
        current = Date(timeIntervalSince1970: 120 * 60)
        machine.tick()

        try expect(machine.state == .reminding, "expected reminder to stay visible after inactivity")
        try expect(machine.bubbleText == "休息一下吧", "expected reminder bubble to stay visible after inactivity")
    },
    TestCase(name: "pet state machine runs in drag direction") {
        let machine = PetStateMachine(now: { Date(timeIntervalSince1970: 0) })

        machine.handle(.dragged(.left))
        try expect(machine.state == .dragRunningLeft, "expected left drag to show left running")

        machine.handle(.animationCompleted)
        machine.handle(.dragged(.right))
        try expect(machine.state == .dragRunningRight, "expected right drag to show right running")
    },
    TestCase(name: "pet state machine waves before reminder settles") {
        let machine = PetStateMachine(now: { Date(timeIntervalSince1970: 0) })

        machine.handle(.reminderFired(.rest))
        try expect(machine.state == .waving, "expected reminder to start with waving feedback")
        try expect(machine.activeReminderKind == .rest, "expected active rest reminder")

        machine.handle(.animationCompleted)
        try expect(machine.state == .reminding, "expected waving reminder to settle into persistent reminder")
        try expect(machine.bubbleText == "休息一下吧", "expected reminder bubble to stay visible")
    },
    TestCase(name: "automatic running carries direction") {
        let machine = PetStateMachine(now: { Date(timeIntervalSince1970: 0) })

        machine.handle(.automaticAction(.running(.left)))
        try expect(machine.state == .automaticRunningLeft, "expected automatic left running")

        machine.handle(.animationCompleted)
        machine.handle(.automaticAction(.running(.right)))
        try expect(machine.state == .automaticRunningRight, "expected automatic right running")
    },
    TestCase(name: "automatic expressive actions use the requested behavior") {
        let machine = PetStateMachine(now: { Date(timeIntervalSince1970: 0) })

        machine.handle(.automaticAction(.expressive(.review)))
        try expect(machine.state == .reviewing, "expected automatic review action")

        machine.handle(.animationCompleted)
        machine.handle(.automaticAction(.expressive(.wait)))
        try expect(machine.state == .waiting, "expected automatic wait action")
    }
]
