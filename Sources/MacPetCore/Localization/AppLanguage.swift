import Foundation

public enum AppLanguage: String, CaseIterable, Sendable {
    case system
    case chinese = "zh-Hans"
    case english = "en"

    public func resolved(preferredLanguages: [String] = Locale.preferredLanguages) -> AppLanguage {
        switch self {
        case .chinese, .english:
            return self
        case .system:
            return preferredLanguages.contains { $0.lowercased().hasPrefix("zh") } ? .chinese : .english
        }
    }
}
