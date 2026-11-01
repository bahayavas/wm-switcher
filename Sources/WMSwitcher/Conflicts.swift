import Foundation

/// WM'lerin kendi kısayollarını okur, bir kısayolun nerede kullanıldığını söyler.
///   AeroSpace: aerospace.toml [mode.main.binding]
///   hyprmac:   hyprmac.conf `bind = MODS, KEY, ...`
///   Amethyst:  uygulamadaki default.amethyst + amethyst.yml'deki değişiklikler
enum Conflicts {
    struct Use: Hashable {
        let wm: String
        let description: String
    }

    static func scan(_ wms: [WM]) -> [Shortcut: [Use]] {
        var out: [Shortcut: [Use]] = [:]
        for wm in wms where wm.installed {
            let uses: [(Shortcut, String)]
            switch wm.id {
            case "aerospace": uses = aerospace(wm.configPath)
            case "hyprmac": uses = hyprmac(wm.configPath)
            case "amethyst": uses = amethyst(appPath: wm.appPath, yml: wm.configPath)
            default: uses = []
            }
            for (s, d) in uses { out[s, default: []].append(Use(wm: wm.name, description: d)) }
        }
        return out
    }

    private static func lines(_ path: String) -> [String] {
        ((try? String(contentsOfFile: path, encoding: .utf8)) ?? "").components(separatedBy: "\n")
    }

    // MARK: AeroSpace

    static func aerospace(_ path: String) -> [(Shortcut, String)] {
        var inMain = false
        var out: [(Shortcut, String)] = []
        for raw in lines(path) {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("[") {
                inMain = line == "[mode.main.binding]"
                continue
            }
            guard inMain, !line.hasPrefix("#"), let eq = line.firstIndex(of: "=") else { continue }
            let key = line[..<eq].trimmingCharacters(in: .whitespaces)
            guard let s = Shortcut(spec: key) else { continue }
            var cmd = line[line.index(after: eq)...].trimmingCharacters(in: .whitespaces)
            if let hash = cmd.range(of: " #") { cmd = String(cmd[..<hash.lowerBound]) }
            cmd = cmd.replacingOccurrences(of: "'", with: "")
            out.append((s, "\(key) → \(cmd.prefix(40))"))
        }
        return out
    }

    // MARK: hyprmac

    static func hyprmac(_ path: String) -> [(Shortcut, String)] {
        var vars: [String: String] = [:]
        var out: [(Shortcut, String)] = []
        for raw in lines(path) {
            let line = raw.components(separatedBy: "#")[0].trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("$"), let eq = line.firstIndex(of: "=") {
                vars[line[..<eq].trimmingCharacters(in: .whitespaces)] =
                    line[line.index(after: eq)...].trimmingCharacters(in: .whitespaces)
                continue
            }
            guard line.hasPrefix("bind"), let eq = line.firstIndex(of: "=") else { continue }
            let fields = line[line.index(after: eq)...].split(separator: ",", omittingEmptySubsequences: false)
                .map { $0.trimmingCharacters(in: .whitespaces) }
            guard fields.count >= 3 else { continue }
            let mods = fields[0].split(separator: " ").flatMap { tok -> [String] in
                let t = String(tok)
                return (vars[t] ?? t).split(separator: " ").map { KeyNames.modifierAlias(String($0)) }
            }
            guard let s = Shortcut(spec: (mods + [fields[1]]).joined(separator: "-")) else { continue }
            let what = fields[2...].filter { !$0.isEmpty }.joined(separator: " ")
            out.append((s, "\(fields[0]), \(fields[1]) → \(what.prefix(40))"))
        }
        return out
    }

    // MARK: Amethyst

    static func amethyst(appPath: String, yml: String) -> [(Shortcut, String)] {
        let defaultsPath = appPath + "/Contents/Resources/default.amethyst"
        guard let data = FileManager.default.contents(atPath: defaultsPath),
              var conf = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else { return [] }
        for (k, v) in parseYAML(yml) { conf[k] = v }

        let mod1 = conf["mod1"] as? [String] ?? []
        let mod2 = conf["mod2"] as? [String] ?? []
        var out: [(Shortcut, String)] = []
        for (command, value) in conf {
            guard let b = value as? [String: Any], let key = b["key"] as? String else { continue }
            let mods: [String]
            switch b["mod"] as? String {
            case "mod1": mods = mod1
            case "mod2": mods = mod2
            default: continue
            }
            let spec = (mods.map { KeyNames.modifierAlias($0) } + [key]).joined(separator: "-")
            if let s = Shortcut(spec: spec) { out.append((s, command)) }
        }
        return out
    }

    /// amethyst.yml için yeterli küçük YAML: üst düzey anahtarlar, `- liste` ve tek seviye `alt: değer`.
    static func parseYAML(_ path: String) -> [String: Any] {
        var out: [String: Any] = [:]
        var current: String?
        var list: [String] = []
        var map: [String: String] = [:]
        func flush() {
            guard let c = current else { return }
            if !list.isEmpty { out[c] = list } else if !map.isEmpty { out[c] = map }
            list = []; map = [:]
        }
        for raw in lines(path) {
            let noComment = raw.components(separatedBy: "#")[0]
            guard !noComment.trimmingCharacters(in: .whitespaces).isEmpty else { continue }
            let indented = noComment.first == " " || noComment.first == "\t"
            let line = noComment.trimmingCharacters(in: .whitespaces)
            if !indented {
                flush()
                let parts = line.split(separator: ":", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
                current = parts[0]
                if parts.count == 2, !parts[1].isEmpty { out[parts[0]] = unquote(parts[1]); current = nil }
            } else if line.hasPrefix("- ") {
                list.append(unquote(String(line.dropFirst(2))))
            } else if let colon = line.firstIndex(of: ":") {
                map[line[..<colon].trimmingCharacters(in: .whitespaces)] =
                    unquote(line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces))
            }
        }
        flush()
        return out
    }

    private static func unquote(_ s: String) -> String {
        s.trimmingCharacters(in: CharacterSet(charactersIn: "\"' "))
    }
}
