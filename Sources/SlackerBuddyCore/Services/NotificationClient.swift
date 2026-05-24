import Foundation
import UserNotifications

public protocol NotificationClientProtocol: Sendable {
    func requestAuthorization() async throws -> Bool
    func sendRestReminder()
}

public struct NotificationClient: NotificationClientProtocol, Sendable {
    public init() {}

    public func requestAuthorization() async throws -> Bool {
        try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
    }

    public func sendRestReminder() {
        let content = UNMutableNotificationContent()
        content.title = "SlackerBuddy"
        content.body = "休息一下吧"
        content.sound = .default
        let request = UNNotificationRequest(identifier: "mac-pet-rest-reminder-\(UUID().uuidString)", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
