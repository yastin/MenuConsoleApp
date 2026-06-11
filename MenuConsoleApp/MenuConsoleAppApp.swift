import SwiftUI
import Cocoa

@main
struct MenuConsoleAppApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!
    private let debugLog = false
    private var settingsWindow: NSWindow?

    // MARK: - Configuration

    private var projectPath: String {
        let raw = UserDefaults.standard.string(forKey: "projectPath") ?? "~/DZO/dzo_local_environment"
        return NSString(string: raw).expandingTildeInPath
    }

    private var composeFileEnv: String {
        let files = UserDefaults.standard.string(forKey: "composeFiles") ?? "docker-compose.yml, docker-compose.override.yml"
        return files
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .map { "\(projectPath)/\($0)" }
            .joined(separator: ":")
    }

    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.applicationIconImage = makeAppIcon()
        setupMenuBar()
    }

    // MARK: - Menu

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "shippingbox", accessibilityDescription: "Docker")
        }

        let menu = NSMenu()

        addItem(menu, title: "ALL", action: #selector(runAll))
        addItem(menu, title: "MY", action: #selector(runMy))
        addItem(menu, title: "MINI", action: #selector(runMini))
        addItem(menu, title: "MINI_EXTERNAL", action: #selector(runMiniExternal))
        addItem(menu, title: "FRONT", action: #selector(runFront))

        menu.addItem(NSMenuItem.separator())

        addItem(menu, title: "STOP", action: #selector(runStop))
        addItem(menu, title: "DOWN", action: #selector(runDown))

        menu.addItem(NSMenuItem.separator())

        addItem(menu, title: "Settings…", action: #selector(openSettings))

        let quitItem = NSMenuItem(
            title: "Quit",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    private func addItem(_ menu: NSMenu, title: String, action: Selector) {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        menu.addItem(item)
    }

    // MARK: - Settings

    @objc private func openSettings() {
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let view = NSHostingView(rootView: SettingsView())
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 150),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Settings"
        window.contentView = view
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow = window
    }

    // MARK: - Actions (SH equivalents)

    /// all)
    @objc private func runAll() {
        runCommand("""
        docker compose up -d
        """)
    }

    /// my)
    @objc private func runMy() {
        runCommand("""
        docker compose up -d web user_php search_php entity_php econtracting_php search_php_workers entity_php_workers search_feed legacy_es legacy_cron legacy_php mysql postgres mongo rabbit redis elasticsearch && \
        docker compose stop binotel kibana
        """)
    }

    /// mini)
    @objc private func runMini() {
        runCommand("""
        docker compose up -d web user_php search_php entity_php econtracting_php legacy_es legacy_php mysql postgres mongo rabbit redis elasticsearch && \
        docker compose stop binotel kibana
        """)
    }

    /// mini_external)
    @objc private func runMiniExternal() {
        runCommand("""
        docker compose up -d web user_php search_php entity_php econtracting_php legacy_es legacy_php redis && \
        docker compose stop binotel kibana mysql postgres mongo rabbit elasticsearch
        """)
    }

    /// front)
    @objc private func runFront() {
        runCommand("""
        docker compose up -d frontend
        """)
    }

    /// stop)
    @objc private func runStop() {
        runCommand("""
        docker compose stop
        """)
    }

    /// down)
    @objc private func runDown() {
        runCommand("""
        docker compose down
        """)
    }

    // MARK: - App Icon

    private func makeAppIcon() -> NSImage {
        let size: CGFloat = 512
        return NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            let inset = rect.insetBy(dx: 20, dy: 20)
            let path = NSBezierPath(roundedRect: inset, xRadius: 100, yRadius: 100)

            let gradient = NSGradient(
                starting: NSColor(srgbRed: 0.13, green: 0.59, blue: 0.95, alpha: 1),
                ending: NSColor(srgbRed: 0.06, green: 0.31, blue: 0.78, alpha: 1)
            )
            gradient?.draw(in: path, angle: -90)

            if let symbol = NSImage(systemSymbolName: "shippingbox.fill", accessibilityDescription: nil) {
                let config = NSImage.SymbolConfiguration(pointSize: 200, weight: .light)
                    .applying(NSImage.SymbolConfiguration(paletteColors: [.white]))
                if let configured = symbol.withSymbolConfiguration(config) {
                    let symbolSize = configured.size
                    let origin = NSPoint(
                        x: (rect.width - symbolSize.width) / 2,
                        y: (rect.height - symbolSize.height) / 2
                    )
                    configured.draw(at: origin, from: .zero, operation: .sourceOver, fraction: 1)
                }
            }

            return true
        }
    }

    // MARK: - Universal Runner

    private func runCommand(_ command: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.currentDirectoryURL = URL(fileURLWithPath: projectPath)
        process.environment = [
            "PATH": "/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin",
            "COMPOSE_FILE": composeFileEnv
        ]
        process.arguments = ["-c", command]

        if debugLog {
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe

            process.terminationHandler = { proc in
                let output = pipe.fileHandleForReading.readDataToEndOfFile()
                if let str = String(data: output, encoding: .utf8), !str.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    print("[DZO]", str)
                }
                try? pipe.fileHandleForReading.close()
            }
        }

        do {
            try process.run()
            print("[INFO] Executed:", command)
        } catch {
            print("[ERROR] Failed:", error)
        }
    }
}
