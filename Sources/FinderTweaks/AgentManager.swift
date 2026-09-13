import AppKit
import FinderTweaksCore
import ServiceManagement

@MainActor
final class AgentManager {
    enum ManagerError: LocalizedError {
        case missingAgent

        var errorDescription: String? {
            switch self {
            case .missingAgent:
                return "The background agent is missing from this copy of Finder Tweaks."
            }
        }
    }

    private let settingsStore = SettingsStore.shared
    private let runtimeStateStore = AgentRuntimeStateStore.shared

    var isRunning: Bool {
        !NSRunningApplication.runningApplications(
            withBundleIdentifier: AppConstants.agentBundleIdentifier
        ).isEmpty
    }

    var runtimeState: AgentRuntimeState {
        guard isRunning else {
            return .stopped
        }
        return runtimeStateStore.state
    }

    var loginItemStatus: SMAppService.Status {
        SMAppService.loginItem(identifier: AppConstants.agentBundleIdentifier).status
    }

    func start() throws {
        guard !isRunning else {
            return
        }

        let agentURL = Bundle.main.bundleURL
            .appendingPathComponent("Contents", isDirectory: true)
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("LoginItems", isDirectory: true)
            .appendingPathComponent("Finder Tweaks Agent.app", isDirectory: true)

        guard FileManager.default.fileExists(atPath: agentURL.path) else {
            throw ManagerError.missingAgent
        }

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = false
        configuration.addsToRecentItems = false
        NSWorkspace.shared.openApplication(
            at: agentURL,
            configuration: configuration,
            completionHandler: { _, error in
                if error != nil {
                    AgentRuntimeStateStore.shared.state = .failedToStart
                }
            }
        )
    }

    func stop() {
        DistributedNotificationCenter.default().post(
            name: AppConstants.stopAgentNotification,
            object: nil
        )

        for application in NSRunningApplication.runningApplications(
            withBundleIdentifier: AppConstants.agentBundleIdentifier
        ) {
            application.terminate()
        }
    }

    func updateLaunchAtLogin(_ enabled: Bool) throws {
        let service = SMAppService.loginItem(identifier: AppConstants.agentBundleIdentifier)
        if enabled {
            if service.status == .notRegistered {
                try service.register()
            }
        } else if service.status != .notRegistered {
            try service.unregister()
        }

        settingsStore.set(enabled, for: .launchAtLogin)
    }

    func reconcileOnLaunch() throws {
        let settings = settingsStore.read()
        var registrationError: Error?

        if settings.launchAtLogin, loginItemStatus == .notRegistered {
            do {
                try updateLaunchAtLogin(true)
            } catch {
                registrationError = error
            }
        }

        if settings.enabled {
            try start()
        }

        if let registrationError {
            throw registrationError
        }
    }
}
