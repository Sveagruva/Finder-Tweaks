import Foundation

public enum AppConstants {
    public static let appBundleIdentifier = "com.sveagruva.FinderTweaks"
    public static let agentBundleIdentifier = "com.sveagruva.FinderTweaks.agent"
    public static let finderBundleIdentifier = "com.apple.finder"
    public static let preferencesSuiteName = "com.sveagruva.FinderTweaks.shared"

    public static let settingsChangedNotification = Notification.Name(
        "com.sveagruva.FinderTweaks.settingsChanged"
    )
    public static let stopAgentNotification = Notification.Name(
        "com.sveagruva.FinderTweaks.stopAgent"
    )
    public static let agentStatusChangedNotification = Notification.Name(
        "com.sveagruva.FinderTweaks.agentStatusChanged"
    )
}
