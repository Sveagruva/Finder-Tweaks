import Darwin
import Foundation

public enum FinderFocusPolicy {
    public static func acceptsTweakedKey(
        frontmostBundleIdentifier: String?,
        focusedElementOwnerPID: pid_t?,
        finderPID: pid_t
    ) -> Bool {
        frontmostBundleIdentifier == AppConstants.finderBundleIdentifier
            && focusedElementOwnerPID == finderPID
    }
}
