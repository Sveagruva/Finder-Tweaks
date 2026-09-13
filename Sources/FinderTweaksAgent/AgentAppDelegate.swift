import AppKit
import ApplicationServices
import FinderTweaksCore

final class AgentAppDelegate: NSObject, NSApplicationDelegate {
    private let settingsStore = SettingsStore.shared
    private let runtimeStateStore = AgentRuntimeStateStore.shared
    private lazy var eventTapController = FinderEventTapController { [weak self] state in
        self?.runtimeStateStore.state = state
    }
    private var trustTimer: Timer?
    private var observers: [NSObjectProtocol] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.prohibited)

        guard settingsStore.read().enabled else {
            runtimeStateStore.state = .stopped
            NSApp.terminate(nil)
            return
        }

        runtimeStateStore.state = .starting
        observeSettings()
        eventTapController.start()
        updateAccessibilityState()
    }

    func applicationWillTerminate(_ notification: Notification) {
        trustTimer?.invalidate()
        observers.forEach(DistributedNotificationCenter.default().removeObserver)
        observers.removeAll()
        eventTapController.stop()
        runtimeStateStore.state = .stopped
    }

    private func observeSettings() {
        let distributedCenter = DistributedNotificationCenter.default()

        observers.append(
            distributedCenter.addObserver(
                forName: AppConstants.settingsChangedNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.applySettings()
            }
        )

        observers.append(
            distributedCenter.addObserver(
                forName: AppConstants.stopAgentNotification,
                object: nil,
                queue: .main
            ) { _ in
                NSApp.terminate(nil)
            }
        )
    }

    private func applySettings() {
        guard settingsStore.read().enabled else {
            NSApp.terminate(nil)
            return
        }

        eventTapController.reloadSettings()
    }

    private func updateAccessibilityState() {
        guard !AXIsProcessTrusted() else {
            trustTimer?.invalidate()
            trustTimer = nil
            eventTapController.accessibilityDidBecomeAvailable()
            return
        }

        runtimeStateStore.state = .waitingForAccessibility
        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        AXIsProcessTrustedWithOptions([promptKey: true] as CFDictionary)

        trustTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard AXIsProcessTrusted() else {
                return
            }

            self?.updateAccessibilityState()
        }
    }
}
