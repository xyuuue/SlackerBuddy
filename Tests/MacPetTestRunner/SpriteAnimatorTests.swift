import Foundation
import MacPetCore

let spriteAnimatorTests: [TestCase] = [
    TestCase(name: "sprite animator cycles idle frames") {
        let animator = SpriteAnimator()

        try expect(animator.frame(for: .idle, elapsed: 0, lowerDistractionMode: false) == "idle-0", "expected first idle frame")
        try expect(animator.frame(for: .idle, elapsed: 0.5, lowerDistractionMode: false) == "idle-1", "expected second idle frame")
        try expect(animator.frame(for: .idle, elapsed: 1.0, lowerDistractionMode: false) == "tail-sway-0", "expected first tail sway frame")
    },
    TestCase(name: "sprite animator uses sleep frames while sleeping") {
        let animator = SpriteAnimator()

        try expect(animator.frame(for: .sleeping, elapsed: 0, lowerDistractionMode: false) == "sleep-0", "expected first sleep frame")
        try expect(animator.frame(for: .sleeping, elapsed: 1.0, lowerDistractionMode: false) == "sleep-1", "expected second sleep frame")
    },
    TestCase(name: "sprite animator slows idle frames in lower distraction mode") {
        let animator = SpriteAnimator()

        try expect(animator.frame(for: .idle, elapsed: 0.5, lowerDistractionMode: true) == "idle-0", "expected lower distraction to hold first idle frame")
        try expect(animator.frame(for: .idle, elapsed: 2.0, lowerDistractionMode: true) == "idle-1", "expected lower distraction to advance after slower duration")
    },
    TestCase(name: "sprite animator advances reminder frames quickly") {
        let animator = SpriteAnimator()

        try expect(animator.frame(for: .reminding, elapsed: 0, lowerDistractionMode: false) == "reminder-0", "expected first reminder frame")
        try expect(animator.frame(for: .reminding, elapsed: 0.25, lowerDistractionMode: false) == "reminder-1", "expected second reminder frame")
    },
    TestCase(name: "automatic running is suppressed in lower distraction mode") {
        let animator = SpriteAnimator()

        let frame = animator.frame(for: .automaticRunning, elapsed: 0, lowerDistractionMode: true)

        try expect(frame.hasPrefix("idle"), "Expected lower distraction mode to suppress automatic running frames")
    },
    TestCase(name: "sprite animator cycles frames instead of going out of range") {
        let animator = SpriteAnimator()

        try expect(animator.frame(for: .petting, elapsed: 0.5, lowerDistractionMode: false) == "petting-0", "expected petting frames to cycle")
    }
]
