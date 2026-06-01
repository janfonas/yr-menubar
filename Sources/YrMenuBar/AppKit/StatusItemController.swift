import AppKit
import SwiftUI
import Combine

/// A borderless panel that can become key so SwiftUI controls inside it
/// (buttons, the segmented picker) receive clicks, and which closes itself
/// when the user clicks elsewhere (handled by the controller on `resignKey`).
final class PopoverPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

/// Owns the `NSStatusItem` and a custom rounded, vibrant `NSPanel` hosting the
/// SwiftUI `ContentView`. This replaces SwiftUI's `MenuBarExtra(.window)` so we
/// can control the panel's chrome (corner radius, vibrancy), present it with a
/// spring "zoom" animation, and offer a real right-click menu on the icon.
@MainActor
final class StatusItemController: NSObject, NSWindowDelegate {
    private let container: AppContainer
    private let actions = MenuActions()

    private var statusItem: NSStatusItem!
    private var panel: PopoverPanel!
    private var hostingView: NSHostingView<AnyView>!
    private var vibrancyView: NSVisualEffectView!

    private var cancellables = Set<AnyCancellable>()
    private var globalClickMonitor: Any?
    private var aboutWindow: NSWindow?
    private var settingsWindow: NSWindow?

    private let panelSize = CGSize(width: 360, height: 540)
    private let cornerRadius: CGFloat = 14

    init(container: AppContainer) {
        self.container = container
        super.init()
        wireActions()
        buildStatusItem()
        buildPanel()
        observeStores()
        updateButtonImage()
    }

    // MARK: - Setup

    private func wireActions() {
        actions.openSettings = { [weak self] in self?.openSettings() }
        actions.openAbout = { [weak self] in self?.showAbout() }
        actions.quit = { NSApp.terminate(nil) }
        actions.closePanel = { [weak self] in self?.hidePanel() }
    }

    private func buildStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.target = self
            button.action = #selector(statusItemClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.imagePosition = .imageOnly
        }
    }

    private func buildPanel() {
        let panel = PopoverPanel(
            contentRect: NSRect(origin: .zero, size: panelSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false)
        panel.level = .popUpMenu
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.delegate = self
        panel.animationBehavior = .none

        // Vibrant, rounded container.
        let vibrancy = NSVisualEffectView(frame: NSRect(origin: .zero, size: panelSize))
        vibrancy.material = .menu
        vibrancy.blendingMode = .behindWindow
        vibrancy.state = .active
        vibrancy.wantsLayer = true
        vibrancy.layer?.cornerRadius = cornerRadius
        vibrancy.layer?.masksToBounds = true
        vibrancy.autoresizingMask = [.width, .height]

        // SwiftUI content, clipped to the same rounded rect.
        let hosting = NSHostingView(rootView: makeRootView())
        hosting.frame = vibrancy.bounds
        hosting.autoresizingMask = [.width, .height]
        hosting.wantsLayer = true
        hosting.layer?.cornerRadius = cornerRadius
        hosting.layer?.masksToBounds = true
        vibrancy.addSubview(hosting)

        panel.contentView = vibrancy
        self.panel = panel
        self.vibrancyView = vibrancy
        self.hostingView = hosting
    }

    private func makeRootView() -> AnyView {
        AnyView(
            ContentView()
                .environmentObject(container.settings)
                .environmentObject(container.location)
                .environmentObject(container.store)
                .environmentObject(container.alerts)
                .environmentObject(actions)
                .frame(width: panelSize.width, height: panelSize.height)
        )
    }

    // MARK: - Icon

    private func observeStores() {
        // `objectWillChange` fires *before* the value mutates, so read on the
        // next runloop tick to pick up the new state.
        for publisher in [container.store.objectWillChange, container.alerts.objectWillChange] {
            publisher
                .receive(on: RunLoop.main)
                .sink { [weak self] _ in self?.updateButtonImage() }
                .store(in: &cancellables)
        }
    }

    private func updateButtonImage() {
        guard let button = statusItem.button else { return }
        button.image = MenuBarIcon.image(
            symbolCode: container.store.currentSymbolCode,
            hasAlerts: !container.alerts.alerts.isEmpty,
            worstSeverityRank: container.alerts.worstSeverityRank)
    }

    // MARK: - Click handling

    @objc private func statusItemClicked() {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp
            || (event?.type == .leftMouseUp && event?.modifierFlags.contains(.control) == true) {
            showContextMenu()
        } else {
            togglePanel()
        }
    }

    private func showContextMenu() {
        let menu = NSMenu()
        menu.addItem(withTitle: L10n.t(.settings), action: #selector(menuOpenSettings), keyEquivalent: "")
            .target = self
        menu.addItem(withTitle: L10n.t(.about), action: #selector(menuOpenAbout), keyEquivalent: "")
            .target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: L10n.t(.quit), action: #selector(menuQuit), keyEquivalent: "q")
            .target = self

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        // Detach so left-clicks resume toggling the panel.
        statusItem.menu = nil
    }

    @objc private func menuOpenSettings() { openSettings() }
    @objc private func menuOpenAbout() { showAbout() }
    @objc private func menuQuit() { NSApp.terminate(nil) }

    // MARK: - Panel show / hide

    private func togglePanel() {
        if panel.isVisible {
            hidePanel()
        } else {
            showPanel()
        }
    }

    private func showPanel() {
        positionPanel()
        // Refresh on open, matching the old MenuBarExtra behaviour.
        container.store.refreshIfNeeded()
        container.alerts.refresh()

        panel.alphaValue = 1
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        animateZoomIn()
        installGlobalClickMonitor()
    }

    private func hidePanel() {
        removeGlobalClickMonitor()
        panel.orderOut(nil)
    }

    private func positionPanel() {
        guard let button = statusItem.button, let buttonWindow = button.window else { return }
        let buttonRect = button.convert(button.bounds, to: nil)
        let screenRect = buttonWindow.convertToScreen(buttonRect)
        let screen = buttonWindow.screen ?? NSScreen.main
        let visible = screen?.visibleFrame ?? .zero

        var x = screenRect.midX - panelSize.width / 2
        // Keep on-screen horizontally with an 8pt margin.
        x = min(max(x, visible.minX + 8), visible.maxX - panelSize.width - 8)
        let y = screenRect.minY - panelSize.height - 6
        panel.setFrame(NSRect(x: x, y: y, width: panelSize.width, height: panelSize.height), display: true)
    }

    /// Spring scale + fade so the panel "zooms" open from the menu bar.
    private func animateZoomIn() {
        guard let layer = vibrancyView.layer else { return }
        layer.removeAllAnimations()

        let scale = CASpringAnimation(keyPath: "transform.scale")
        scale.fromValue = 0.94
        scale.toValue = 1.0
        scale.mass = 1
        scale.stiffness = 240
        scale.damping = 20
        scale.initialVelocity = 6
        scale.duration = scale.settlingDuration

        let fade = CABasicAnimation(keyPath: "opacity")
        fade.fromValue = 0.0
        fade.toValue = 1.0
        fade.duration = 0.16
        fade.timingFunction = CAMediaTimingFunction(name: .easeOut)

        layer.add(scale, forKey: "zoomScale")
        layer.add(fade, forKey: "zoomFade")
    }

    // MARK: - Click-outside dismissal

    private func installGlobalClickMonitor() {
        removeGlobalClickMonitor()
        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.hidePanel()
        }
    }

    private func removeGlobalClickMonitor() {
        if let monitor = globalClickMonitor {
            NSEvent.removeMonitor(monitor)
            globalClickMonitor = nil
        }
    }

    func windowDidResignKey(_ notification: Notification) {
        guard (notification.object as? NSWindow) === panel else { return }
        hidePanel()
    }

    // MARK: - Settings / About

    private func openSettings() {
        hidePanel()
        if settingsWindow == nil {
            let root = SettingsView(onDone: { [weak self] in self?.settingsWindow?.close() })
                .environmentObject(container.settings)
                .environmentObject(container.location)
                .environmentObject(container.store)
                .environmentObject(container.alerts)
                .frame(width: 460)
            let hosting = NSHostingController(rootView: root)
            let window = NSWindow(contentViewController: hosting)
            window.title = L10n.t(.settings).replacingOccurrences(of: "…", with: "")
            window.styleMask = [.titled, .closable]
            window.isReleasedWhenClosed = false
            window.center()
            settingsWindow = window
        }
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    private func showAbout() {
        hidePanel()
        if aboutWindow == nil {
            let hosting = NSHostingController(rootView: AboutView())
            let window = NSWindow(contentViewController: hosting)
            window.title = L10n.t(.about)
            window.styleMask = [.titled, .closable]
            window.isReleasedWhenClosed = false
            window.center()
            aboutWindow = window
        }
        NSApp.activate(ignoringOtherApps: true)
        aboutWindow?.makeKeyAndOrderFront(nil)
    }

    deinit {
        if let monitor = globalClickMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
