public struct LocalizedStrings: Sendable {
    public enum Key: Sendable {
        case settingsTitle
        case languageLabel
        case petLabel
        case showPetMenu
        case hidePetMenu
        case quitMenu
        case petSectionTitle
        case petSizeLabel
        case showPetOnLaunch
        case lowerDistractionMode
        case resetPetPosition
        case remindersSectionTitle
        case reminderIntervalLabel
        case sleepDelayLabel
        case minuteSuffix
        case systemLanguageOption
        case systemNotifications
        case restReminderBubble
    }

    private let language: AppLanguage

    public init(language: AppLanguage) {
        self.language = language.resolved()
    }

    public func text(_ key: Key) -> String {
        switch language {
        case .chinese:
            return chineseText(key)
        case .english, .system:
            return englishText(key)
        }
    }

    private func englishText(_ key: Key) -> String {
        switch key {
        case .settingsTitle:
            return "Settings"
        case .languageLabel:
            return "Language"
        case .petLabel:
            return "Pet"
        case .showPetMenu:
            return "Show Pet"
        case .hidePetMenu:
            return "Hide Pet"
        case .quitMenu:
            return "Quit"
        case .petSectionTitle:
            return "Pet"
        case .petSizeLabel:
            return "Size"
        case .showPetOnLaunch:
            return "Show pet on launch"
        case .lowerDistractionMode:
            return "Lower-distraction mode"
        case .resetPetPosition:
            return "Reset pet position"
        case .remindersSectionTitle:
            return "Reminders"
        case .reminderIntervalLabel:
            return "Reminder interval"
        case .sleepDelayLabel:
            return "Sleep delay"
        case .minuteSuffix:
            return "min"
        case .systemLanguageOption:
            return "System"
        case .systemNotifications:
            return "System notifications"
        case .restReminderBubble:
            return "Time for a break"
        }
    }

    private func chineseText(_ key: Key) -> String {
        switch key {
        case .settingsTitle:
            return "设置"
        case .languageLabel:
            return "语言"
        case .petLabel:
            return "宠物"
        case .showPetMenu:
            return "显示宠物"
        case .hidePetMenu:
            return "隐藏宠物"
        case .quitMenu:
            return "退出"
        case .petSectionTitle:
            return "宠物"
        case .petSizeLabel:
            return "大小"
        case .showPetOnLaunch:
            return "启动时显示宠物"
        case .lowerDistractionMode:
            return "低干扰模式"
        case .resetPetPosition:
            return "重置宠物位置"
        case .remindersSectionTitle:
            return "提醒"
        case .reminderIntervalLabel:
            return "提醒间隔"
        case .sleepDelayLabel:
            return "睡眠延迟"
        case .minuteSuffix:
            return "分钟"
        case .systemLanguageOption:
            return "跟随系统"
        case .systemNotifications:
            return "系统通知"
        case .restReminderBubble:
            return "休息一下吧"
        }
    }
}
