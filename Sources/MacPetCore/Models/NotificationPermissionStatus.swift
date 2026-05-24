import Foundation

public enum NotificationPermissionStatus: Equatable, Sendable {
    case off
    case requesting
    case enabled
    case denied
    case failed
}
