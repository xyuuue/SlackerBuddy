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
            for language in preferredLanguages {
                let languageCode = language.lowercased()
                if languageCode.hasPrefix("zh") {
                    return .chinese
                }
                if languageCode.hasPrefix("en") {
                    return .english
                }
            }
            return .english
        }
    }
}
