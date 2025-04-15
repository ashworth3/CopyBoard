import Cocoa
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    let showDockKey = "ShowDockIcon"
    let floatKey = "FloatOnTop"

    func applicationDidFinishLaunching(_ notification: Notification) {
        let defaults = UserDefaults.standard

        // Set default settings if not already set
        if defaults.object(forKey: showDockKey) == nil {
            defaults.set(false, forKey: showDockKey) // Hide dock by default
        }

        if defaults.object(forKey: floatKey) == nil {
            defaults.set(true, forKey: floatKey) // Float window by default
        }

        if SMAppService.mainApp.status != .enabled {
            do {
                try SMAppService.mainApp.register() // Launch at login by default
            } catch {
                print("Failed to register for launch at login: \(error)")
            }
        }

        let showDock = defaults.bool(forKey: showDockKey)
        let shouldFloat = defaults.bool(forKey: floatKey)

        NSApp.setActivationPolicy(showDock ? .regular : .accessory)

        // Menu bar icon
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.title = "📋"
            button.action = #selector(showWindow)
            button.target = self
        }

        // Build menu
        let menu = NSMenu()

        let openItem = NSMenuItem(title: "Open CopyBoard", action: #selector(showWindow), keyEquivalent: "")
        openItem.target = self
        menu.addItem(openItem)

        menu.addItem(.separator())
        
        let dockToggleItem = NSMenuItem(title: "Show Dock Icon", action: #selector(toggleDockIcon(_:)), keyEquivalent: "")
        dockToggleItem.state = showDock ? .on : .off
        dockToggleItem.target = self
        menu.addItem(dockToggleItem)

        let floatItem = NSMenuItem(title: "Float on Top", action: #selector(toggleFloat(_:)), keyEquivalent: "")
        floatItem.state = shouldFloat ? .on : .off
        floatItem.target = self
        menu.addItem(floatItem)

        let launchAtLoginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin(_:)), keyEquivalent: "")
        launchAtLoginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        launchAtLoginItem.target = self
        menu.addItem(launchAtLoginItem)

        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit", action: #selector(NSApp.terminate(_:)), keyEquivalent: "q")

        statusItem?.menu = menu

        // Apply "Float on Top" setting on launch
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let shouldFloat = UserDefaults.standard.bool(forKey: self.floatKey)
            for window in NSApp.windows {
                if window.title == "CopyBoard" {
                    window.level = shouldFloat ? .floating : .normal
                }
            }
        }
    }

    @objc func showWindow() {
        NSApp.activate(ignoringOtherApps: true)
        let shouldFloat = UserDefaults.standard.bool(forKey: floatKey)

        for window in NSApp.windows {
            if window.title == "CopyBoard" {
                window.level = shouldFloat ? .floating : .normal
                window.makeKeyAndOrderFront(nil)
                break
            }
        }
    }

    @objc func toggleFloat(_ sender: NSMenuItem) {
        let newState = sender.state == .off
        UserDefaults.standard.set(newState, forKey: floatKey)
        sender.state = newState ? .on : .off

        for window in NSApp.windows {
            if window.title == "CopyBoard" {
                window.level = newState ? .floating : .normal
            }
        }
    }

    @objc func toggleDockIcon(_ sender: NSMenuItem) {
        let newState = sender.state == .off
        UserDefaults.standard.set(newState, forKey: showDockKey)

        sender.state = newState ? .on : .off
        NSApp.setActivationPolicy(newState ? .regular : .accessory)

        if newState {
            showWindow()
        }
    }

    @objc func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
                sender.state = .off
            } else {
                try SMAppService.mainApp.register()
                sender.state = .on
            }
        } catch {
            print("Failed to toggle launch at login: \(error)")
        }
    }
}
