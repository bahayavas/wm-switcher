import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    let switcher = Switcher()
    private var window: NSWindow?
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ note: Notification) {
        NSApp.mainMenu = makeMainMenu()

        // Login item olarak açıldıysa pencere gösterme, son seçilen WM'i başlat
        let event = NSAppleEventManager.shared().currentAppleEvent
        let launchedAtLogin = event?.eventID == kAEOpenApplication
            && event?.paramDescriptor(forKeyword: keyAEPropData)?.enumCodeValue == keyAELaunchedAsLogInItem
        if launchedAtLogin {
            switcher.restore()
        } else {
            showWindow()
        }
        // Global kısayollar Switcher içinde kaydediliyor (shortcuts.json)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        showWindow()
        return false
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        switcher.refresh()
        let menu = NSMenu()
        menu.autoenablesItems = false
        for wm in switcher.wms {
            let item = NSMenuItem(title: wm.installed ? wm.name : "\(wm.name) (kurulu değil)",
                                  action: #selector(dockSwitch(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = wm.id
            item.state = switcher.active == wm.id ? .on : .off
            item.isEnabled = wm.installed && switcher.busy == nil
            menu.addItem(item)
        }
        menu.addItem(.separator())
        let none = NSMenuItem(title: "Hepsini kapat", action: #selector(dockSwitch(_:)), keyEquivalent: "")
        none.target = self
        none.representedObject = "none"
        none.state = switcher.active == "none" ? .on : .off
        none.isEnabled = switcher.busy == nil
        menu.addItem(none)
        menu.addItem(.separator())
        let settings = NSMenuItem(title: "Ayarlar…", action: #selector(showSettings), keyEquivalent: "")
        settings.target = self
        menu.addItem(settings)
        return menu
    }

    @objc private func dockSwitch(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String else { return }
        switcher.switchTo(id)
    }

    @objc func showWindow() {
        if window == nil {
            window = makeWindow(title: "WM Switcher", content: ContentView())
            window?.center()
        }
        switcher.load()
        switcher.refresh()
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }

    @objc func showSettings() {
        if settingsWindow == nil {
            let w = makeWindow(title: "WM Switcher Ayarları", content: SettingsView())
            w.delegate = self
            if let main = window, main.isVisible {
                w.setFrameTopLeftPoint(NSPoint(x: main.frame.maxX + 16, y: main.frame.maxY))
            } else {
                w.center()
            }
            settingsWindow = w
        }
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    // Ayarlar kapanınca yarım kalan kısayol kaydını iptal et
    func windowWillClose(_ notification: Notification) {
        if notification.object as? NSWindow === settingsWindow { switcher.stopRecording() }
    }

    func windowDidResignKey(_ notification: Notification) {
        if notification.object as? NSWindow === settingsWindow { switcher.stopRecording() }
    }

    private func makeWindow<V: View>(title: String, content: V) -> NSWindow {
        let host = NSHostingView(rootView: content.environmentObject(switcher))
        let w = NSWindow(contentRect: NSRect(origin: .zero, size: host.fittingSize),
                         styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
                         backing: .buffered, defer: false)
        w.title = title
        w.titlebarAppearsTransparent = true
        w.titleVisibility = .hidden
        w.isMovableByWindowBackground = true
        w.backgroundColor = NSColor(red: 0x1a / 255, green: 0x1b / 255, blue: 0x26 / 255, alpha: 1)
        w.appearance = NSAppearance(named: .darkAqua)
        w.contentView = host
        w.isReleasedWhenClosed = false
        return w
    }

    private func makeMainMenu() -> NSMenu {
        let main = NSMenu()

        let appItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "WM Switcher Hakkında",
                        action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        let settings = appMenu.addItem(withTitle: "Ayarlar…", action: #selector(showSettings), keyEquivalent: ",")
        settings.target = self
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "WM Switcher'ı Gizle", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "WM Switcher'dan Çık", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu
        main.addItem(appItem)

        let winItem = NSMenuItem()
        let winMenu = NSMenu(title: "Pencere")
        let switcherWin = winMenu.addItem(withTitle: "WM Switcher", action: #selector(showWindow), keyEquivalent: "0")
        switcherWin.target = self
        winMenu.addItem(withTitle: "Kapat", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        winMenu.addItem(withTitle: "Küçült", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        winItem.submenu = winMenu
        main.addItem(winItem)
        NSApp.windowsMenu = winMenu
        return main
    }
}

/// Test için: WMSwitcher --snapshot <main|settings> <çıktı.png> — pencereyi açmadan görünümü PNG'ye çizer.
@MainActor
func snapshot(_ which: String, to path: String) {
    let sw = Switcher()
    sw.scanConflicts()
    let root = which == "settings" ? AnyView(SettingsView()) : AnyView(ContentView())
    let host = NSHostingView(rootView: root.environmentObject(sw))
    host.appearance = NSAppearance(named: .darkAqua)
    host.frame = NSRect(origin: .zero, size: host.fittingSize)
    host.layoutSubtreeIfNeeded()
    guard let rep = host.bitmapImageRepForCachingDisplay(in: host.bounds) else { exit(1) }
    host.cacheDisplay(in: host.bounds, to: rep)
    try? rep.representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: path))
    exit(0)
}

MainActor.assumeIsolated {
    let args = CommandLine.arguments
    if let i = args.firstIndex(of: "--snapshot"), args.count > i + 2 {
        _ = NSApplication.shared
        snapshot(args[i + 1], to: args[i + 2])
    }
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.setActivationPolicy(.regular)
    app.run()
}
