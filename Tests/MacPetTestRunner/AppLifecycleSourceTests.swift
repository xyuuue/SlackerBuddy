import Foundation

let appLifecycleSourceTests: [TestCase] = [
    TestCase(name: "pet view does not own reminder scheduler lifecycle") {
        let sourceURL = URL(fileURLWithPath: "Sources/MacPet/Views/PetView.swift")
        let source = try String(contentsOf: sourceURL, encoding: .utf8)

        try expect(!source.contains("scheduler.start("), "PetView should not start the reminder scheduler")
        try expect(!source.contains("scheduler.tick("), "PetView should not tick the reminder scheduler")
        try expect(!source.contains("scheduler.updateInterval("), "PetView should not update scheduler intervals")
        try expect(!source.contains("scheduler.onReminder"), "PetView should not assign reminder callbacks")
    }
]
