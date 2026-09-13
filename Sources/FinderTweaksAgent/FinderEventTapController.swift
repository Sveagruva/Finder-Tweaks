import AppKit
import CoreGraphics
import FinderTweaksCore

final class FinderEventTapController {
    private let reportState: (AgentRuntimeState) -> Void
    private let settingsStore = SettingsStore.shared
    private var settings = FinderTweaksSettings()
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var finderPID: pid_t?
    private var workspaceObservers: [NSObjectProtocol] = []

    init(reportState: @escaping (AgentRuntimeState) -> Void) {
        self.reportState = reportState
    }

    func start() {
        settings = settingsStore.read()
        observeFinderLifecycle()

        if AXIsProcessTrusted() {
            installForRunningFinder()
        }
    }

    func stop() {
        workspaceObservers.forEach(NSWorkspace.shared.notificationCenter.removeObserver)
        workspaceObservers.removeAll()
        removeEventTap()
    }

    func reloadSettings() {
        settings = settingsStore.read()
    }

    func accessibilityDidBecomeAvailable() {
        installForRunningFinder()
    }

    private func observeFinderLifecycle() {
        let center = NSWorkspace.shared.notificationCenter

        workspaceObservers.append(
            center.addObserver(
                forName: NSWorkspace.didLaunchApplicationNotification,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                guard let application = notification.userInfo?[NSWorkspace.applicationUserInfoKey]
                        as? NSRunningApplication,
                      application.bundleIdentifier == AppConstants.finderBundleIdentifier else {
                    return
                }

                self?.installEventTap(for: application.processIdentifier)
            }
        )

        workspaceObservers.append(
            center.addObserver(
                forName: NSWorkspace.didTerminateApplicationNotification,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                guard let application = notification.userInfo?[NSWorkspace.applicationUserInfoKey]
                        as? NSRunningApplication,
                      application.bundleIdentifier == AppConstants.finderBundleIdentifier else {
                    return
                }

                self?.removeEventTap()
            }
        )
    }

    private func installForRunningFinder() {
        guard let finder = NSRunningApplication.runningApplications(
            withBundleIdentifier: AppConstants.finderBundleIdentifier
        ).first else {
            reportState(.finderUnavailable)
            return
        }

        installEventTap(for: finder.processIdentifier)
    }

    private func installEventTap(for processIdentifier: pid_t) {
        guard finderPID != processIdentifier || eventTap == nil else {
            return
        }

        removeEventTap()

        let eventMask = CGEventMask(1) << CGEventType.keyDown.rawValue
        let context = Unmanaged.passUnretained(self).toOpaque()

        guard let tap = CGEvent.tapCreateForPid(
            pid: processIdentifier,
            place: .tailAppendEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: finderEventTapCallback,
            userInfo: context
        ) else {
            reportState(.failedToAttach)
            return
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        eventTap = tap
        runLoopSource = source
        finderPID = processIdentifier
        reportState(.active)
    }

    private func removeEventTap() {
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }

        if let eventTap {
            CFMachPortInvalidate(eventTap)
        }

        runLoopSource = nil
        eventTap = nil
        finderPID = nil
    }

    fileprivate func handle(
        proxy: CGEventTapProxy,
        type: CGEventType,
        event: CGEvent
    ) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        guard type == .keyDown,
              event.getIntegerValueField(.keyboardEventAutorepeat) == 0,
              let finderPID,
              let action = KeyMapping.action(
                  for: CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode)),
                  flags: event.flags,
                  settings: settings
              ),
              FinderContext.acceptsTweakedKey(for: finderPID) else {
            return Unmanaged.passUnretained(event)
        }

        post(action, through: proxy)
        return nil
    }

    private func post(_ action: FinderAction, through proxy: CGEventTapProxy) {
        let keyCode: CGKeyCode
        let flags: CGEventFlags

        switch action {
        case .openSelectedItems:
            keyCode = FinderKeyCode.downArrow
            flags = .maskCommand
        case .renameSelectedItem:
            keyCode = FinderKeyCode.returnKey
            flags = []
        case .moveSelectedItemsToTrash:
            keyCode = FinderKeyCode.delete
            flags = .maskCommand
        }

        guard let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false) else {
            return
        }

        keyDown.flags = flags
        keyUp.flags = flags
        keyDown.tapPostEvent(proxy)
        keyUp.tapPostEvent(proxy)
    }
}

private let finderEventTapCallback: CGEventTapCallBack = { proxy, type, event, userInfo in
    guard let userInfo else {
        return Unmanaged.passUnretained(event)
    }

    let controller = Unmanaged<FinderEventTapController>
        .fromOpaque(userInfo)
        .takeUnretainedValue()
    return controller.handle(proxy: proxy, type: type, event: event)
}
