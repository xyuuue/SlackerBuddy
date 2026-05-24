import Foundation
import MacPetCore

let localizationTests: [TestCase] = [
    TestCase(name: "system language resolves Chinese preferred locale") {
        let language = AppLanguage.system.resolved(preferredLanguages: ["zh-Hans-US", "en-US"])
        try expect(language == .chinese, "Expected Chinese locale to resolve to Chinese")
    },
    TestCase(name: "system language resolves English for non Chinese locale") {
        let language = AppLanguage.system.resolved(preferredLanguages: ["fr-FR", "en-US"])
        try expect(language == .english, "Expected non-Chinese locale to resolve to English")
    },
    TestCase(name: "localized strings switch settings labels") {
        let zh = LocalizedStrings(language: .chinese)
        let en = LocalizedStrings(language: .english)
        try expect(zh.text(.settingsTitle) == "设置", "Expected Chinese settings title")
        try expect(en.text(.settingsTitle) == "Settings", "Expected English settings title")
    },
    TestCase(name: "localized reminder bubble switches copy") {
        try expect(LocalizedStrings(language: .chinese).text(.restReminderBubble) == "休息一下吧", "Expected Chinese reminder copy")
        try expect(LocalizedStrings(language: .english).text(.restReminderBubble) == "Time for a break", "Expected English reminder copy")
    }
]
