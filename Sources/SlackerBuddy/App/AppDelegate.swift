import AppKit

extension Notification.Name {
    static let macPetWillTerminate = Notification.Name("macPetWillTerminate")
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationWillTerminate(_ notification: Notification) {
        NotificationCenter.default.post(name: .macPetWillTerminate, object: nil)
    }
}
