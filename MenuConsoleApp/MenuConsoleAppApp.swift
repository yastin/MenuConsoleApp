import SwiftUI
import Cocoa

@main
struct MenuConsoleAppApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Без окон
        Settings {
            EmptyView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!
    private let debugLog = false

    // MARK: - Constants

    private let rawProjectPath = "~/DZO/dzo_local_environment"
    private var projectPath: String { NSString(string: rawProjectPath).expandingTildeInPath }

    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
    }

    // MARK: - Menu

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "terminal", accessibilityDescription: "DZO")
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

    // MARK: - Universal Runner

    private func runCommand(_ command: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.currentDirectoryURL = URL(fileURLWithPath: projectPath)
        process.environment = [
            "PATH": "/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin",
            "COMPOSE_FILE": "\(projectPath)/docker-compose.yml:\(projectPath)/docker-compose.override.yml"
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
