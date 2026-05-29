import Foundation
import SlackerBuddyCore

let localizationTests: [TestCase] = [
    TestCase(name: "system language resolves Chinese preferred locale") {
        let language = AppLanguage.system.resolved(preferredLanguages: ["zh-Hans-US", "en-US"])
        try expect(language == .chinese, "Expected Chinese locale to resolve to Chinese")
    },
    TestCase(name: "system language resolves English for non Chinese locale") {
        let language = AppLanguage.system.resolved(preferredLanguages: ["fr-FR", "en-US"])
        try expect(language == .english, "Expected non-Chinese locale to resolve to English")
    },
    TestCase(name: "system language respects English before Chinese preference order") {
        let language = AppLanguage.system.resolved(preferredLanguages: ["en-US", "zh-Hans"])
        try expect(language == .english, "Expected first supported English locale to resolve to English")
    },
    TestCase(name: "system language respects Chinese before English preference order") {
        let language = AppLanguage.system.resolved(preferredLanguages: ["zh-Hans", "en-US"])
        try expect(language == .chinese, "Expected first supported Chinese locale to resolve to Chinese")
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
    },
    TestCase(name: "localized reminder and autonomy strings switch copy") {
        let zh = LocalizedStrings(language: .chinese)
        let en = LocalizedStrings(language: .english)
        try expect(zh.text(.enableRestReminders) == "开启休息提醒", "Expected Chinese rest toggle")
        try expect(en.text(.enableRestReminders) == "Enable rest reminders", "Expected English rest toggle")
        try expect(zh.text(.waterReminderBubble) == "喝点水吧", "Expected Chinese water copy")
        try expect(en.text(.waterReminderBubble) == "Time to drink water", "Expected English water copy")
        try expect(zh.text(.secondsSuffix) == "秒", "Expected Chinese seconds suffix")
        try expect(en.text(.percentSuffix) == "%", "Expected English percent suffix")
        try expect(zh.text(.reminderIntervalLabel) == "休息间隔", "Expected Chinese rest interval label")
        try expect(en.text(.reminderIntervalLabel) == "Rest interval", "Expected English rest interval label")
        try expect(zh.text(.restBlockingEnabled) == "休息时放大挡屏", "Expected Chinese rest blocking label")
        try expect(en.text(.restBlockingEnabled) == "Enlarge pet during rest", "Expected English rest blocking label")
        try expect(zh.text(.restBlockingDuration) == "挡屏时长", "Expected Chinese rest blocking duration label")
        try expect(en.text(.restBlockingDuration) == "Blocking duration", "Expected English rest blocking duration label")
        try expect(zh.text(.restBlockingScale) == "挡屏比例", "Expected Chinese rest blocking scale label")
        try expect(en.text(.restBlockingScale) == "Blocking scale", "Expected English rest blocking scale label")
        try expect(zh.text(.restBlockingReturnButton) == "我回来啦！", "Expected Chinese return button label")
        try expect(en.text(.restBlockingReturnButton) == "I'm back!", "Expected English return button label")
        try expect(zh.text(.bubbleDurationLabel) == "气泡显示时长", "Expected Chinese bubble duration label")
        try expect(en.text(.bubbleDurationLabel) == "Bubble duration", "Expected English bubble duration label")
        try expect(zh.text(.automaticActionFrequency) == "动作频率", "Expected Chinese action frequency label")
        try expect(en.text(.automaticActionFrequency) == "Action frequency", "Expected English action frequency label")
        try expect(zh.text(.automaticRunDirection) == "跑动方向", "Expected Chinese running direction label")
        try expect(en.text(.automaticRunDirection) == "Run direction", "Expected English running direction label")
        try expect(zh.text(.automaticRunDirectionRandom) == "随机", "Expected Chinese random direction")
        try expect(en.text(.automaticRunDirectionLeft) == "Left", "Expected English left direction")
        try expect(en.text(.automaticRunDirectionRight) == "Right", "Expected English right direction")
        try expect(zh.text(.notificationRequesting) == "正在请求权限", "Expected Chinese requesting notification status")
        try expect(en.text(.notificationEnabled) == "Notifications enabled", "Expected English enabled notification status")
        try expect(zh.text(.notificationDenied) == "通知权限被拒绝", "Expected Chinese denied notification status")
        try expect(en.text(.notificationFailed) == "Notification setup failed", "Expected English failed notification status")
        try expect(zh.text(.diskImageCleanupMoveToTrash) == "移到废纸篓", "Expected Chinese disk image cleanup button")
        try expect(en.text(.diskImageCleanupMoveToTrash) == "Move to Trash", "Expected English disk image cleanup button")
        try expect(zh.text(.diskImageCleanupKeep) == "保留", "Expected Chinese keep button")
        try expect(en.text(.diskImageCleanupKeep) == "Keep", "Expected English keep button")
    }
]
