import AppKit

extension Notification.Name {
    static let macPetWillTerminate = Notification.Name("macPetWillTerminate")
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationWillTerminate(_ notification: Notification) {
        NotificationCenter.default.post(name: .macPetWillTerminate, object: nil)
    }
}
