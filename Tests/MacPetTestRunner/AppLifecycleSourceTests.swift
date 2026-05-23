import Foundation

let appLifecycleSourceTests: [TestCase] = [
    TestCase(name: "pet view does not own reminder scheduler lifecycle") {
        let sourceURL = URL(fileURLWithPath: "Sources/MacPet/Views/PetView.swift")
        let source = try String(contentsOf: sourceURL, encoding: .utf8)

        try expect(!source.contains("scheduler.start("), "PetView should not start the reminder scheduler")
        try expect(!source.contains("scheduler.tick("), "PetView should not tick the reminder scheduler")
        try expect(!source.contains("scheduler.updateInterval("), "PetView should not update scheduler intervals")
        try expect(!source.contains("scheduler.onReminder"), "PetView should not assign reminder callbacks")
    },
    TestCase(name: "window movement is reported as pet interaction") {
        let controllerSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/MacPet/Windowing/PetWindowController.swift"),
            encoding: .utf8
        )
        let runtimeSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/MacPet/App/AppRuntime.swift"),
            encoding: .utf8
        )

        try expect(controllerSource.contains("public var onMoved: (() -> Void)?"), "PetWindowController should expose a movement callback")
        try expect(controllerSource.contains("self?.onMoved?()"), "PetWindowController should invoke movement callback after window moves")
        try expect(runtimeSource.contains("petWindowController.onMoved"), "AppRuntime should bind window movement to pet state")
        try expect(runtimeSource.contains("handle(.dragged)"), "Window movement should reset pet inactivity through dragged event")
    }
]
