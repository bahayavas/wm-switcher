import SwiftUI

/// Tokyo Night
enum TN {
    static let bg = Color(hex: 0x1a1b26)
    static let card = Color(hex: 0x24283b)
    static let border = Color(hex: 0x3b4261)
    static let fg = Color(hex: 0xc0caf5)
    static let dim = Color(hex: 0x565f89)
    static let blue = Color(hex: 0x7aa2f7)
    static let purple = Color(hex: 0xbb9af7)
    static let red = Color(hex: 0xf7768e)
    static let green = Color(hex: 0x9ece6a)

    static func font(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .custom("Maple Mono NF", size: size).weight(weight)
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xff) / 255, green: Double((hex >> 8) & 0xff) / 255,
                  blue: Double(hex & 0xff) / 255)
    }
}

struct ContentView: View {
    @EnvironmentObject var sw: Switcher

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                ForEach(sw.wms) { wm in
                    WMCard(wm: wm)
                }
            }

            Button { sw.switchTo("none") } label: {
                HStack(spacing: 8) {
                    if sw.busy == "none" { ProgressView().controlSize(.small) }
                    Text("Hepsini kapat (normal macOS)")
                    if let s = sw.shortcut("none") { Text(s.display).foregroundStyle(TN.dim) }
                }
                .font(TN.font(13, .medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 10).fill(sw.active == "none" ? TN.purple.opacity(0.18) : TN.card))
                .overlay(RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(sw.active == "none" ? TN.purple : TN.border, lineWidth: sw.active == "none" ? 2 : 1))
                .foregroundStyle(TN.fg)
            }
            .buttonStyle(.plain)
            .disabled(sw.busy != nil)

            HStack {
                Toggle("Login'de başlat", isOn: Binding(get: { sw.loginEnabled }, set: { sw.setLogin($0) }))
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .tint(TN.blue)
                Spacer()
                Button {
                    (NSApp.delegate as? AppDelegate)?.showSettings()
                } label: {
                    Label("Ayarlar", systemImage: "gearshape")
                }
                .buttonStyle(.plain)
                .foregroundStyle(TN.blue)
            }
            .font(TN.font(12))
            .foregroundStyle(TN.fg)

            if let err = sw.error {
                Text(err).font(TN.font(12)).foregroundStyle(TN.red).lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(18)
        .frame(width: 520)
        .background(TN.bg)
        .onAppear { sw.refresh() }
    }
}

struct WMCard: View {
    @EnvironmentObject var sw: Switcher
    let wm: WM

    private var isActive: Bool { sw.active == wm.id }

    var body: some View {
        VStack(spacing: 8) {
            Button { sw.switchTo(wm.id) } label: {
                VStack(spacing: 6) {
                    ZStack {
                        Text(wm.letter)
                            .font(TN.font(44, .bold))
                            .foregroundStyle(isActive
                                ? AnyShapeStyle(LinearGradient(colors: [TN.blue, TN.purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                                : AnyShapeStyle(TN.fg))
                        if sw.busy == wm.id { ProgressView().controlSize(.small).offset(y: 34) }
                    }
                    .frame(height: 64)
                    Text(wm.name).font(TN.font(14, .semibold)).foregroundStyle(TN.fg)
                    Text(status).font(TN.font(11)).foregroundStyle(isActive ? TN.green : TN.dim)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(RoundedRectangle(cornerRadius: 12).fill(isActive ? TN.blue.opacity(0.15) : TN.card))
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isActive
                        ? AnyShapeStyle(LinearGradient(colors: [TN.blue, TN.purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                        : AnyShapeStyle(TN.border), lineWidth: isActive ? 2 : 1))
                .contentShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .disabled(!wm.installed || sw.busy != nil)

            Button("Ayar dosyasını aç") { sw.openConfig(wm) }
                .font(TN.font(11))
                .buttonStyle(.plain)
                .foregroundStyle(wm.hasConfig ? TN.blue : TN.dim)
                .disabled(!wm.hasConfig)
                .help(wm.hasConfig ? wm.configPath : "Henüz yok — \(wm.name) bir kez çalışınca oluşur: \(wm.configPath)")
        }
        .opacity(wm.installed ? 1 : 0.35)
        .saturation(wm.installed ? 1 : 0)
    }

    private var status: String {
        if !wm.installed { return "kurulu değil" }
        if isActive { return "● aktif" }
        return sw.shortcut(wm.id)?.display ?? " "
    }
}
