import AppKit
import FinderTweaksCore
import ServiceManagement

@MainActor
final class SettingsWindowController: NSWindowController, NSWindowDelegate {
    private let settingsStore = SettingsStore.shared
    private let agentManager = AgentManager()

    private var mappingSwitches: [SettingKey: NSSwitch] = [:]
    private let enabledSwitch = NSSwitch()
    private let launchAtLoginSwitch = NSSwitch()
    private let statusLabel = NSTextField(labelWithString: "Starting…")
    private let accessibilityButton = NSButton(title: "Open System Settings", target: nil, action: nil)
    private var refreshTimer: Timer?
    private var statusObserver: NSObjectProtocol?

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 540, height: 470),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Finder Tweaks"
        window.center()
        window.isReleasedWhenClosed = false
        window.sharingType = .readOnly

        super.init(window: window)
        window.delegate = self
        buildInterface()
        loadSettings()
        observeAgentStatus()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        refreshTimer?.invalidate()
        if let statusObserver {
            DistributedNotificationCenter.default().removeObserver(statusObserver)
        }
    }

    func refresh() {
        loadSettings()
        refreshStatus()
    }

    func windowWillClose(_ notification: Notification) {
        NSApp.terminate(nil)
    }

    private func buildInterface() {
        guard let window else {
            return
        }

        let contentView = NSView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        window.contentView = contentView

        let titleLabel = NSTextField(labelWithString: "Finder Tweaks")
        titleLabel.font = .systemFont(ofSize: 22, weight: .semibold)

        let subtitleLabel = NSTextField(
            wrappingLabelWithString: "Change a small set of keys only while Finder is active. The background agent keeps running when this window is closed."
        )
        subtitleLabel.textColor = .secondaryLabelColor

        enabledSwitch.target = self
        enabledSwitch.action = #selector(enabledChanged(_:))
        let enabledRow = labeledSwitchRow(label: "Enabled", control: enabledSwitch, emphasized: true)

        let itemsLabel = sectionLabel("Items")
        let mappings = NSStackView(views: [
            mappingRow(key: .returnOpensItems, input: "Return", action: "Open selected items"),
            mappingRow(key: .enterOpensItems, input: "Keypad Enter", action: "Open selected items"),
            mappingRow(key: .f2RenamesItem, input: "F2", action: "Rename selected item"),
            mappingRow(key: .deleteMovesItemsToTrash, input: "Delete", action: "Move selected items to Trash"),
            mappingRow(
                key: .forwardDeleteMovesItemsToTrash,
                input: "Forward Delete",
                action: "Move selected items to Trash"
            ),
        ])
        mappings.orientation = .vertical
        mappings.alignment = .leading
        mappings.spacing = 9

        let generalLabel = sectionLabel("General")
        launchAtLoginSwitch.target = self
        launchAtLoginSwitch.action = #selector(launchAtLoginChanged(_:))
        let launchRow = labeledSwitchRow(label: "Launch at login", control: launchAtLoginSwitch)

        statusLabel.font = .systemFont(ofSize: NSFont.smallSystemFontSize, weight: .medium)
        accessibilityButton.bezelStyle = .rounded
        accessibilityButton.controlSize = .small
        accessibilityButton.target = self
        accessibilityButton.action = #selector(openAccessibilitySettings)

        let statusRow = NSStackView(views: [
            NSTextField(labelWithString: "Agent status"),
            flexibleSpacer(),
            statusLabel,
            accessibilityButton,
        ])
        statusRow.orientation = .horizontal
        statusRow.alignment = .centerY
        statusRow.spacing = 10

        let safetyNote = NSTextField(
            wrappingLabelWithString: "Tweaks pause while renaming text, using Finder dialogs, or holding Shift, Control, Option, or Command."
        )
        safetyNote.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        safetyNote.textColor = .secondaryLabelColor

        let stack = NSStackView(views: [
            titleLabel,
            subtitleLabel,
            separator(),
            enabledRow,
            separator(),
            itemsLabel,
            mappings,
            separator(),
            generalLabel,
            launchRow,
            statusRow,
            safetyNote,
        ])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12

        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 22),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -22),
            subtitleLabel.widthAnchor.constraint(equalTo: stack.widthAnchor),
            mappings.widthAnchor.constraint(equalTo: stack.widthAnchor),
            enabledRow.widthAnchor.constraint(equalTo: stack.widthAnchor),
            launchRow.widthAnchor.constraint(equalTo: stack.widthAnchor),
            statusRow.widthAnchor.constraint(equalTo: stack.widthAnchor),
            safetyNote.widthAnchor.constraint(equalTo: stack.widthAnchor),
        ])
    }

    private func mappingRow(key: SettingKey, input: String, action: String) -> NSView {
        let toggle = NSSwitch()
        toggle.identifier = NSUserInterfaceItemIdentifier(key.rawValue)
        toggle.target = self
        toggle.action = #selector(mappingChanged(_:))
        mappingSwitches[key] = toggle

        let inputLabel = NSTextField(labelWithString: input)
        inputLabel.font = .systemFont(ofSize: NSFont.systemFontSize, weight: .medium)
        inputLabel.widthAnchor.constraint(equalToConstant: 130).isActive = true

        let actionLabel = NSTextField(labelWithString: action)
        actionLabel.textColor = .secondaryLabelColor

        let row = NSStackView(views: [toggle, inputLabel, actionLabel])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 10
        return row
    }

    private func labeledSwitchRow(label: String, control: NSSwitch, emphasized: Bool = false) -> NSView {
        let label = NSTextField(labelWithString: label)
        if emphasized {
            label.font = .systemFont(ofSize: NSFont.systemFontSize, weight: .semibold)
        }

        let row = NSStackView(views: [label, flexibleSpacer(), control])
        row.orientation = .horizontal
        row.alignment = .centerY
        return row
    }

    private func sectionLabel(_ value: String) -> NSTextField {
        let label = NSTextField(labelWithString: value)
        label.font = .systemFont(ofSize: NSFont.systemFontSize, weight: .semibold)
        return label
    }

    private func separator() -> NSBox {
        let separator = NSBox()
        separator.boxType = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.widthAnchor.constraint(equalToConstant: 492).isActive = true
        return separator
    }

    private func flexibleSpacer() -> NSView {
        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return spacer
    }

    private func loadSettings() {
        let settings = settingsStore.read()
        enabledSwitch.state = settings.enabled ? .on : .off
        mappingSwitches[.returnOpensItems]?.state = settings.returnOpensItems ? .on : .off
        mappingSwitches[.enterOpensItems]?.state = settings.enterOpensItems ? .on : .off
        mappingSwitches[.f2RenamesItem]?.state = settings.f2RenamesItem ? .on : .off
        mappingSwitches[.deleteMovesItemsToTrash]?.state = settings.deleteMovesItemsToTrash ? .on : .off
        mappingSwitches[.forwardDeleteMovesItemsToTrash]?.state = settings.forwardDeleteMovesItemsToTrash ? .on : .off
        launchAtLoginSwitch.state = settings.launchAtLogin ? .on : .off
        mappingSwitches.values.forEach { $0.isEnabled = settings.enabled }
    }

    private func observeAgentStatus() {
        statusObserver = DistributedNotificationCenter.default().addObserver(
            forName: AppConstants.agentStatusChangedNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refreshStatus()
            }
        }

        refreshTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshStatus()
            }
        }
        refreshStatus()
    }

    private func refreshStatus() {
        let settings = settingsStore.read()
        guard settings.enabled else {
            setStatus("Stopped", color: .secondaryLabelColor, showsAccessibilityButton: false)
            return
        }

        switch agentManager.runtimeState {
        case .starting, .stopped:
            setStatus("Starting…", color: .secondaryLabelColor, showsAccessibilityButton: false)
        case .waitingForAccessibility:
            setStatus("Accessibility required", color: .systemOrange, showsAccessibilityButton: true)
        case .active:
            setStatus("Active", color: .systemGreen, showsAccessibilityButton: false)
        case .finderUnavailable:
            setStatus("Waiting for Finder", color: .secondaryLabelColor, showsAccessibilityButton: false)
        case .failedToStart:
            setStatus("Unable to start agent", color: .systemRed, showsAccessibilityButton: false)
        case .failedToAttach:
            setStatus("Unable to monitor Finder", color: .systemRed, showsAccessibilityButton: true)
        }
    }

    private func setStatus(_ value: String, color: NSColor, showsAccessibilityButton: Bool) {
        statusLabel.stringValue = value
        statusLabel.textColor = color
        accessibilityButton.isHidden = !showsAccessibilityButton
    }

    @objc private func enabledChanged(_ sender: NSSwitch) {
        let isEnabled = sender.state == .on
        settingsStore.set(isEnabled, for: .enabled)
        mappingSwitches.values.forEach { $0.isEnabled = isEnabled }

        if isEnabled {
            do {
                try agentManager.start()
            } catch {
                settingsStore.set(false, for: .enabled)
                sender.state = .off
                mappingSwitches.values.forEach { $0.isEnabled = false }
                present(error)
            }
        } else {
            agentManager.stop()
        }

        notifySettingsChanged()
        refreshStatus()
    }

    @objc private func mappingChanged(_ sender: NSSwitch) {
        guard let identifier = sender.identifier?.rawValue,
              let key = SettingKey(rawValue: identifier) else {
            return
        }

        settingsStore.set(sender.state == .on, for: key)
        notifySettingsChanged()
    }

    @objc private func launchAtLoginChanged(_ sender: NSSwitch) {
        let enabled = sender.state == .on
        do {
            try agentManager.updateLaunchAtLogin(enabled)
        } catch {
            sender.state = enabled ? .off : .on
            present(error)
        }
    }

    @objc private func openAccessibilitySettings() {
        guard let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        ) else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    private func notifySettingsChanged() {
        DistributedNotificationCenter.default().post(
            name: AppConstants.settingsChangedNotification,
            object: nil
        )
    }

    private func present(_ error: Error) {
        let alert = NSAlert(error: error)
        alert.runModal()
    }
}
