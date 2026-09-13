import AppKit
import ApplicationServices
import FinderTweaksCore

enum FinderContext {
    static func acceptsTweakedKey(for finderPID: pid_t) -> Bool {
        guard NSWorkspace.shared.frontmostApplication?.bundleIdentifier == AppConstants.finderBundleIdentifier else {
            return false
        }

        let finderElement = AXUIElementCreateApplication(finderPID)

        if let focusedElement = copiedAttribute(kAXFocusedUIElementAttribute as CFString, from: finderElement),
           isTextEntryElement(focusedElement) {
            return false
        }

        guard let focusedWindow = copiedAttribute(kAXFocusedWindowAttribute as CFString, from: finderElement) else {
            return true
        }

        if let roleDescription = stringAttribute(kAXRoleDescriptionAttribute as CFString, from: focusedWindow),
           roleDescription.localizedCaseInsensitiveContains("dialog") {
            return false
        }

        if let subrole = stringAttribute(kAXSubroleAttribute as CFString, from: focusedWindow),
           subrole == kAXDialogSubrole as String {
            return false
        }

        return true
    }

    private static func isTextEntryElement(_ element: AXUIElement) -> Bool {
        guard let role = stringAttribute(kAXRoleAttribute as CFString, from: element) else {
            return false
        }

        return role == kAXTextFieldRole as String
            || role == kAXTextAreaRole as String
            || role == kAXComboBoxRole as String
    }

    private static func copiedAttribute(_ attribute: CFString, from element: AXUIElement) -> AXUIElement? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute, &value) == .success,
              let value,
              CFGetTypeID(value) == AXUIElementGetTypeID() else {
            return nil
        }

        return unsafeBitCast(value, to: AXUIElement.self)
    }

    private static func stringAttribute(_ attribute: CFString, from element: AXUIElement) -> String? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute, &value) == .success else {
            return nil
        }

        return value as? String
    }
}
