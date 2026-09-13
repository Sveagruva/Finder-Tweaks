import CoreGraphics

public enum FinderAction: Equatable, Sendable {
    case openSelectedItems
    case renameSelectedItem
    case moveSelectedItemsToTrash
}

public enum FinderKeyCode {
    public static let returnKey: CGKeyCode = 36
    public static let enter: CGKeyCode = 76
    public static let delete: CGKeyCode = 51
    public static let forwardDelete: CGKeyCode = 117
    public static let f2: CGKeyCode = 120
    public static let downArrow: CGKeyCode = 125
}

public enum KeyMapping {
    private static let conflictingModifiers: CGEventFlags = [
        .maskShift,
        .maskControl,
        .maskAlternate,
        .maskCommand,
    ]

    public static func action(
        for keyCode: CGKeyCode,
        flags: CGEventFlags,
        settings: FinderTweaksSettings
    ) -> FinderAction? {
        guard settings.enabled, flags.intersection(conflictingModifiers).isEmpty else {
            return nil
        }

        switch keyCode {
        case FinderKeyCode.returnKey where settings.returnOpensItems:
            return .openSelectedItems
        case FinderKeyCode.enter where settings.enterOpensItems:
            return .openSelectedItems
        case FinderKeyCode.f2 where settings.f2RenamesItem:
            return .renameSelectedItem
        case FinderKeyCode.delete where settings.deleteMovesItemsToTrash:
            return .moveSelectedItemsToTrash
        case FinderKeyCode.forwardDelete where settings.forwardDeleteMovesItemsToTrash:
            return .moveSelectedItemsToTrash
        default:
            return nil
        }
    }
}
