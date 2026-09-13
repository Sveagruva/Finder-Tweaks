import Foundation

public enum SettingKey: String, CaseIterable, Sendable {
    case enabled
    case returnOpensItems
    case enterOpensItems
    case f2RenamesItem
    case deleteMovesItemsToTrash
    case forwardDeleteMovesItemsToTrash
    case launchAtLogin
}

public struct FinderTweaksSettings: Equatable, Sendable {
    public var enabled: Bool
    public var returnOpensItems: Bool
    public var enterOpensItems: Bool
    public var f2RenamesItem: Bool
    public var deleteMovesItemsToTrash: Bool
    public var forwardDeleteMovesItemsToTrash: Bool
    public var launchAtLogin: Bool

    public init(
        enabled: Bool = true,
        returnOpensItems: Bool = true,
        enterOpensItems: Bool = true,
        f2RenamesItem: Bool = true,
        deleteMovesItemsToTrash: Bool = true,
        forwardDeleteMovesItemsToTrash: Bool = true,
        launchAtLogin: Bool = true
    ) {
        self.enabled = enabled
        self.returnOpensItems = returnOpensItems
        self.enterOpensItems = enterOpensItems
        self.f2RenamesItem = f2RenamesItem
        self.deleteMovesItemsToTrash = deleteMovesItemsToTrash
        self.forwardDeleteMovesItemsToTrash = forwardDeleteMovesItemsToTrash
        self.launchAtLogin = launchAtLogin
    }
}

public final class SettingsStore: @unchecked Sendable {
    public static let shared = SettingsStore()

    private let defaults: UserDefaults

    public init(defaults: UserDefaults? = nil) {
        guard let resolvedDefaults = defaults ?? UserDefaults(suiteName: AppConstants.preferencesSuiteName) else {
            preconditionFailure("Unable to create the shared preferences store")
        }

        self.defaults = resolvedDefaults
        self.defaults.register(defaults: [
            SettingKey.enabled.rawValue: true,
            SettingKey.returnOpensItems.rawValue: true,
            SettingKey.enterOpensItems.rawValue: true,
            SettingKey.f2RenamesItem.rawValue: true,
            SettingKey.deleteMovesItemsToTrash.rawValue: true,
            SettingKey.forwardDeleteMovesItemsToTrash.rawValue: true,
            SettingKey.launchAtLogin.rawValue: true,
        ])
    }

    public func read() -> FinderTweaksSettings {
        FinderTweaksSettings(
            enabled: defaults.bool(forKey: SettingKey.enabled.rawValue),
            returnOpensItems: defaults.bool(forKey: SettingKey.returnOpensItems.rawValue),
            enterOpensItems: defaults.bool(forKey: SettingKey.enterOpensItems.rawValue),
            f2RenamesItem: defaults.bool(forKey: SettingKey.f2RenamesItem.rawValue),
            deleteMovesItemsToTrash: defaults.bool(forKey: SettingKey.deleteMovesItemsToTrash.rawValue),
            forwardDeleteMovesItemsToTrash: defaults.bool(forKey: SettingKey.forwardDeleteMovesItemsToTrash.rawValue),
            launchAtLogin: defaults.bool(forKey: SettingKey.launchAtLogin.rawValue)
        )
    }

    public func set(_ value: Bool, for key: SettingKey) {
        defaults.set(value, forKey: key.rawValue)
    }
}
