import Foundation

public enum AgentRuntimeState: String, Sendable {
    case starting
    case waitingForAccessibility
    case active
    case finderUnavailable
    case failedToStart
    case failedToAttach
    case stopped
}

public final class AgentRuntimeStateStore: @unchecked Sendable {
    public static let shared = AgentRuntimeStateStore()

    private let defaults: UserDefaults
    private let stateKey = "agentRuntimeState"

    public init(defaults: UserDefaults? = nil) {
        guard let resolvedDefaults = defaults ?? UserDefaults(suiteName: AppConstants.preferencesSuiteName) else {
            preconditionFailure("Unable to create the shared runtime state store")
        }
        self.defaults = resolvedDefaults
    }

    public var state: AgentRuntimeState {
        get {
            guard let rawValue = defaults.string(forKey: stateKey),
                  let state = AgentRuntimeState(rawValue: rawValue) else {
                return .stopped
            }
            return state
        }
        set {
            defaults.set(newValue.rawValue, forKey: stateKey)
            DistributedNotificationCenter.default().post(
                name: AppConstants.agentStatusChangedNotification,
                object: nil
            )
        }
    }
}
