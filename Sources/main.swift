// Awake: a small menu-bar app that keeps your Mac awake.
// Click the cup for the sleep/awake toggle. Right-click it for Open at Login and Quit.

import Cocoa
import ServiceManagement
import SwiftUI

/// A borderless, transparent window: the glass capsule is the only thing you see.
final class GlassPanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let model = AwakeModel()
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private var monitors: [Any] = []

    private lazy var panel: GlassPanel = {
        // After a choice, let the pill finish sliding, then close.
        let host = NSHostingView(rootView: PanelView(model: model) { [weak self] in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { self?.hidePanel() }
        })
        let panel = GlassPanel(contentRect: NSRect(origin: .zero, size: host.fittingSize),
                               styleMask: [.borderless, .nonactivatingPanel],
                               backing: .buffered, defer: false)
        panel.contentView = host
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false // the glass draws its own
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .transient, .ignoresCycle, .fullScreenAuxiliary]
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.appearance = NSAppearance(named: .aqua) // always the white look
        return panel
    }()

    func applicationDidFinishLaunching(_ notification: Notification) {
        if let button = statusItem.button {
            button.target = self
            button.action = #selector(statusItemClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        trackIcon()

        let args = CommandLine.arguments
        if args.contains("--on") { model.start() }
        if args.contains("--show-panel") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.showPanel() }
        }
    }

    func applicationWillTerminate(_ notification: Notification) { model.stop() }

    /// Re-renders the menu bar icon whenever the state changes.
    private func trackIcon() {
        withObservationTracking {
            let on = model.isActive
            let image = NSImage(systemSymbolName: on ? "cup.and.saucer.fill" : "cup.and.saucer",
                                accessibilityDescription: on ? "Awake: on" : "Awake: off")
            image?.isTemplate = true
            statusItem.button?.image = image
            statusItem.button?.toolTip = on ? "Awake: on" : "Awake: off"
        } onChange: { [weak self] in
            Task { @MainActor in self?.trackIcon() }
        }
    }

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp || event?.modifierFlags.contains(.control) == true {
            showMenu()
        } else if panel.isVisible {
            hidePanel()
        } else {
            showPanel()
        }
    }

    // MARK: Glass panel

    private func showPanel() {
        guard let button = statusItem.button, let buttonWindow = button.window else { return }
        let anchor = buttonWindow.convertToScreen(button.convert(button.bounds, to: nil))
        let size = panel.frame.size
        var origin = NSPoint(x: anchor.midX - size.width / 2, y: anchor.minY - size.height - 2)
        if let visible = buttonWindow.screen?.visibleFrame {
            origin.x = min(max(origin.x, visible.minX + 4), visible.maxX - size.width - 4)
        }
        panel.setFrameOrigin(origin)
        panel.alphaValue = 0
        NSApp.activate()
        panel.makeKeyAndOrderFront(nil)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            panel.animator().alphaValue = 1
        }

        // Close on a click anywhere else, or on Escape.
        let outside = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            MainActor.assumeIsolated { self?.hidePanel() }
        }
        let escape = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.keyCode == 53 else { return event }
            MainActor.assumeIsolated { self?.hidePanel() }
            return nil
        }
        monitors = [outside, escape].compactMap { $0 }
    }

    private func hidePanel() {
        monitors.forEach { NSEvent.removeMonitor($0) }
        monitors = []
        guard panel.isVisible else { return }
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.12
            panel.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            MainActor.assumeIsolated { self?.panel.orderOut(nil) }
        })
    }

    // MARK: Right-click menu

    private func showMenu() {
        hidePanel()
        let menu = NSMenu()
        menu.delegate = self
        let login = NSMenuItem(title: "Open at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        login.target = self
        login.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(login)
        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Quit Awake", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quit)
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
    }

    func menuDidClose(_ menu: NSMenu) { statusItem.menu = nil }

    @objc private func toggleLaunchAtLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            NSSound.beep()
        }
    }
}

MainActor.assumeIsolated {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.setActivationPolicy(.accessory)
    app.run()
}
