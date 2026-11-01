import AppKit
import Carbon
import ServiceManagement

/// wms.conf'taki bir satır.
struct WM: Identifiable, Equatable {
    let id: String
    let name: String
    let bundleID: String
    let appPath: String
    let configPath: String
    let letter: String

    var installed: Bool { FileManager.default.fileExists(atPath: appPath) }
    var hasConfig: Bool { FileManager.default.fileExists(atPath: configPath) }
}

@MainActor
final class Switcher: ObservableObject {
    static let dir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("wm-switcher")
    static let script = dir.appendingPathComponent("switch.sh").path
    static let conf = dir.appendingPathComponent("wms.conf").path
    static let shortcutsFile = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".config/wm-switcher/shortcuts.json")

    @Published private(set) var wms: [WM] = []
    /// Şu an çalışan WM'in id'si, hiçbiri çalışmıyorsa "none".
    @Published private(set) var active = "none"
    /// Geçiş sürerken hedef id'si.
    @Published private(set) var busy: String?
    @Published var error: String?
    @Published private(set) var loginEnabled = SMAppService.mainApp.status == .enabled

    /// Eylem id'si (WM id'si ya da "none") → kısayol. nil = kısayol yok.
    @Published private(set) var shortcuts: [String: Shortcut?] = [:]
    /// Başka bir uygulama aldığı için kaydedilemeyen eylemler.
    @Published private(set) var unregistered: Set<String> = []
    /// WM ayarlarında hangi kısayolun ne için kullanıldığı (Ayarlar açılınca taranır).
    @Published private(set) var wmBindings: [Shortcut: [Conflicts.Use]] = [:]
    /// Kısayolu kaydedilmekte olan eylem.
    @Published private(set) var recording: String?
    @Published var recordHint: String?
    private var recordMonitor: Any?

    init() {
        load()
        loadShortcuts()
        refresh()
        // NSWorkspace launch/terminate bildirimleri menü bar (LSUIElement) uygulamalarında
        // gelmiyor; runningApplications KVO hepsini görür.
        appsObservation = NSWorkspace.shared.observe(\.runningApplications, options: [.new]) { [weak self] _, change in
            let launched = (change.newValue ?? []).compactMap(\.bundleIdentifier)
            Task { @MainActor in self?.appsChanged(launched: launched) }
        }
    }

    private var appsObservation: NSKeyValueObservation?

    /// Bir WM switcher dışından açıldıysa (Spotlight, kendi kendini yeniden başlatma…)
    /// yeni açılan kazanır: diğerleri kapatılır, seçim kaydedilir.
    private func appsChanged(launched: [String]) {
        if busy == nil, let wm = wms.first(where: { launched.contains($0.bundleID) }) {
            switchTo(wm.id)
        } else {
            refresh()
        }
    }

    func load() {
        guard let text = try? String(contentsOfFile: Self.conf, encoding: .utf8) else {
            error = "wms.conf okunamadı: \(Self.conf)"
            return
        }
        wms = text.split(separator: "\n").compactMap { line in
            let s = line.trimmingCharacters(in: .whitespaces)
            guard !s.isEmpty, !s.hasPrefix("#") else { return nil }
            let f = s.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
            guard f.count >= 6 else { return nil }
            return WM(id: f[0], name: f[1], bundleID: f[2], appPath: f[3],
                      configPath: (f[4] as NSString).expandingTildeInPath, letter: f[5])
        }
    }

    // MARK: Kısayollar

    /// Ayarlar ve Dock menüsündeki sıra: WM'ler, sonra "Hepsini kapat"
    var actionIDs: [String] { wms.map(\.id) + ["none"] }

    func actionName(_ id: String) -> String {
        id == "none" ? "Hepsini kapat" : wms.first { $0.id == id }?.name ?? id
    }

    /// Varsayılan: ⌃⌥⌘ + wms.conf'taki sıra (1-9), "Hepsini kapat" ⌃⌥⌘0
    func defaultShortcut(_ id: String) -> Shortcut? {
        let n = id == "none" ? 0 : (wms.firstIndex { $0.id == id } ?? 99) + 1
        guard n <= 9 else { return nil }
        return Shortcut(spec: "ctrl-alt-cmd-\(n)")
    }

    func shortcut(_ id: String) -> Shortcut? {
        if let s = shortcuts[id] { return s }
        return defaultShortcut(id)
    }

    func loadShortcuts() {
        var map: [String: Shortcut?] = [:]
        if let data = try? Data(contentsOf: Self.shortcutsFile),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: String] {
            for (id, spec) in json { map[id] = spec.isEmpty ? .some(nil) : Shortcut(spec: spec) }
        }
        shortcuts = map
        applyHotKeys()
    }

    func setShortcut(_ id: String, _ s: Shortcut?) {
        shortcuts[id] = .some(s)
        saveShortcuts()
        applyHotKeys()
    }

    func resetShortcuts() {
        shortcuts = [:]
        saveShortcuts()
        applyHotKeys()
    }

    private func saveShortcuts() {
        var json: [String: String] = [:]
        for id in actionIDs { json[id] = shortcut(id)?.spec ?? "" }
        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys])
            try data.write(to: Self.shortcutsFile)
        } catch {
            self.error = "Kısayollar kaydedilemedi: \(error.localizedDescription)"
        }
    }

    func applyHotKeys() {
        HotKeys.unregisterAll()
        var failed: Set<String> = []
        for id in actionIDs {
            guard let s = shortcut(id) else { continue }
            let ok = HotKeys.register(s) { [weak self] in
                MainActor.assumeIsolated { self?.switchTo(id) }
            }
            if !ok { failed.insert(id) }
        }
        unregistered = failed
    }

    func scanConflicts() { wmBindings = Conflicts.scan(wms) }

    /// Aynı kısayolu kullanan diğer switcher eylemleri
    func duplicates(of id: String) -> [String] {
        guard let s = shortcut(id) else { return [] }
        return actionIDs.filter { $0 != id && shortcut($0) == s }
    }

    func startRecording(_ id: String) {
        stopRecording()
        recording = id
        recordHint = nil
        // Kayıt sırasında global kısayollar kapalı: mevcut bir kısayola basınca geçiş yapmasın
        HotKeys.unregisterAll()
        recordMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            MainActor.assumeIsolated { self?.handleRecord(event) }
            return nil
        }
    }

    func stopRecording() {
        if let m = recordMonitor { NSEvent.removeMonitor(m) }
        recordMonitor = nil
        if recording != nil {
            recording = nil
            applyHotKeys()
        }
    }

    private func handleRecord(_ event: NSEvent) {
        guard let id = recording else { return }
        let s = Shortcut(event: event)
        let plain = event.modifierFlags.intersection([.control, .option, .command, .shift]).isEmpty
        if plain && s.keyCode == UInt32(kVK_Escape) {
            stopRecording()
        } else if plain && (s.keyCode == UInt32(kVK_Delete) || s.keyCode == UInt32(kVK_ForwardDelete)) {
            stopRecording()
            setShortcut(id, nil)
        } else if !s.hasRequiredModifier {
            recordHint = "En az bir ⌃ ⌥ ⌘ tuşu gerekli"
        } else if let other = actionIDs.first(where: { $0 != id && shortcut($0) == s }) {
            recordHint = "\(s.display) zaten \(actionName(other)) için kullanılıyor"
        } else {
            stopRecording()
            setShortcut(id, s)
        }
    }

    func refresh() {
        let running = wms.first { !NSRunningApplication.runningApplications(withBundleIdentifier: $0.bundleID).isEmpty }
        active = running?.id ?? "none"
        loginEnabled = SMAppService.mainApp.status == .enabled
        NSApp.dockTile.badgeLabel = running?.letter
    }

    func switchTo(_ id: String) {
        guard busy == nil else { return }
        if id != "none", wms.first(where: { $0.id == id })?.installed != true { return }
        busy = id
        error = nil
        run([id]) { [weak self] status, stderr in
            guard let self else { return }
            busy = nil
            if status != 0 { error = stderr.isEmpty ? "switch.sh çıkış kodu \(status)" : stderr }
            refresh()
        }
    }

    /// Login'de: son seçilen WM'i başlat.
    func restore() {
        busy = "restore"
        run(["restore"]) { [weak self] _, _ in
            self?.busy = nil
            self?.refresh()
        }
    }

    func openConfig(_ wm: WM) {
        guard wm.hasConfig else { return }
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        p.arguments = ["-t", wm.configPath]
        try? p.run()
    }

    func setLogin(_ on: Bool) {
        do {
            if on { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
        } catch {
            self.error = "Login ayarı değişmedi: \(error.localizedDescription)"
        }
        loginEnabled = SMAppService.mainApp.status == .enabled
        if on, SMAppService.mainApp.status == .requiresApproval {
            error = "System Settings → General → Login Items'ta WM Switcher'a izin ver."
        }
    }

    private func run(_ args: [String], done: @escaping @MainActor (Int32, String) -> Void) {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/bin/bash")
        p.arguments = [Self.script] + args
        let errPipe = Pipe()
        p.standardError = errPipe
        p.standardOutput = FileHandle.nullDevice
        p.terminationHandler = { proc in
            let data = errPipe.fileHandleForReading.readDataToEndOfFile()
            // Son satır en anlamlısı (ör. "başka bir geçiş sürüyor")
            let msg = String(decoding: data, as: UTF8.self)
                .split(separator: "\n").last.map { $0.replacingOccurrences(of: "[wm-switcher] ", with: "") } ?? ""
            let status = proc.terminationStatus
            Task { @MainActor in done(status, status == 0 ? "" : msg) }
        }
        do { try p.run() } catch {
            done(-1, "switch.sh çalıştırılamadı: \(error.localizedDescription)")
        }
    }
}
