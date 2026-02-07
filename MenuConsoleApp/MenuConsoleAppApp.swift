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

    // MARK: - Constants

    private let projectPath = "/Volumes/GIGABYTE/DZO/dzo_local_environment"

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

        // Рабочая директория проекта
        process.currentDirectoryURL = URL(fileURLWithPath: projectPath)

        // PATH для GUI-приложения
        process.environment = [
            "PATH": "/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin",
            "COMPOSE_FILE": "\(projectPath)/docker-compose.yml:\(projectPath)/docker-compose.override.yml"
        ]

        process.arguments = [
            "-c",
            command
        ]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        // Логирование
        pipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if !data.isEmpty, let output = String(data: data, encoding: .utf8) {
                print("[DZO]", output.trimmingCharacters(in: .whitespacesAndNewlines))
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
