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
        case minuteSuffix
        case systemLanguageOption
        case systemNotifications
        case restReminderBubble
        case bubbleDurationLabel
        case enableAutomaticActions
        case automaticActionFrequency
        case enableAutomaticRunning
        case automaticRunDirection
        case automaticRunDirectionLeft
        case automaticRunDirectionRight
        case automaticRunDirectionRandom
        case enableRestReminders
        case restBlockingEnabled
        case restBlockingDuration
        case restBlockingScale
        case enableWaterReminders
        case waterIntervalLabel
        case waterReminderBubble
        case secondsSuffix
        case percentSuffix
        case behaviorSectionTitle
        case notificationOff
        case notificationRequesting
        case notificationEnabled
        case notificationDenied
        case notificationFailed
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
            return "Rest interval"
        case .minuteSuffix:
            return "min"
        case .systemLanguageOption:
            return "System"
        case .systemNotifications:
            return "System notifications"
        case .restReminderBubble:
            return "Time for a break"
        case .bubbleDurationLabel:
            return "Bubble duration"
        case .enableAutomaticActions:
            return "Enable automatic actions"
        case .automaticActionFrequency:
            return "Action frequency"
        case .enableAutomaticRunning:
            return "Enable automatic running"
        case .automaticRunDirection:
            return "Run direction"
        case .automaticRunDirectionLeft:
            return "Left"
        case .automaticRunDirectionRight:
            return "Right"
        case .automaticRunDirectionRandom:
            return "Random"
        case .enableRestReminders:
            return "Enable rest reminders"
        case .restBlockingEnabled:
            return "Enlarge pet during rest"
        case .restBlockingDuration:
            return "Blocking duration"
        case .restBlockingScale:
            return "Blocking scale"
        case .enableWaterReminders:
            return "Enable water reminders"
        case .waterIntervalLabel:
            return "Water interval"
        case .waterReminderBubble:
            return "Time to drink water"
        case .secondsSuffix:
            return "sec"
        case .percentSuffix:
            return "%"
        case .behaviorSectionTitle:
            return "Behavior"
        case .notificationOff:
            return "Notifications off"
        case .notificationRequesting:
            return "Requesting permission"
        case .notificationEnabled:
            return "Notifications enabled"
        case .notificationDenied:
            return "Notifications denied"
        case .notificationFailed:
            return "Notification setup failed"
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
            return "休息间隔"
        case .minuteSuffix:
            return "分钟"
        case .systemLanguageOption:
            return "跟随系统"
        case .systemNotifications:
            return "系统通知"
        case .restReminderBubble:
            return "休息一下吧"
        case .bubbleDurationLabel:
            return "气泡显示时长"
        case .enableAutomaticActions:
            return "开启自动动作"
        case .automaticActionFrequency:
            return "动作频率"
        case .enableAutomaticRunning:
            return "开启自动跑动"
        case .automaticRunDirection:
            return "跑动方向"
        case .automaticRunDirectionLeft:
            return "向左"
        case .automaticRunDirectionRight:
            return "向右"
        case .automaticRunDirectionRandom:
            return "随机"
        case .enableRestReminders:
            return "开启休息提醒"
        case .restBlockingEnabled:
            return "休息时放大挡屏"
        case .restBlockingDuration:
            return "挡屏时长"
        case .restBlockingScale:
            return "挡屏比例"
        case .enableWaterReminders:
            return "开启喝水提醒"
        case .waterIntervalLabel:
            return "喝水间隔"
        case .waterReminderBubble:
            return "喝点水吧"
        case .secondsSuffix:
            return "秒"
        case .percentSuffix:
            return "%"
        case .behaviorSectionTitle:
            return "行为"
        case .notificationOff:
            return "通知已关闭"
        case .notificationRequesting:
            return "正在请求权限"
        case .notificationEnabled:
            return "通知已开启"
        case .notificationDenied:
            return "通知权限被拒绝"
        case .notificationFailed:
            return "通知设置失败"
        }
    }
}
