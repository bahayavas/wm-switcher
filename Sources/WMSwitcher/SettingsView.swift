import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var sw: Switcher

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Kısayollar").font(TN.font(16, .bold)).foregroundStyle(TN.fg)
            Text("Değiştirmek için kısayola tıkla, yeni tuşlara bas. ⌫ siler, ⎋ vazgeçer.")
                .font(TN.font(11)).foregroundStyle(TN.dim)

            VStack(spacing: 8) {
                ForEach(sw.actionIDs, id: \.self) { id in
                    ShortcutRow(id: id)
                }
            }

            HStack {
                Button("Varsayılanlara dön (⌃⌥⌘ + sıra)") { sw.resetShortcuts() }
                    .buttonStyle(.plain)
                    .foregroundStyle(TN.blue)
                Spacer()
                Button("shortcuts.json") { NSWorkspace.shared.activateFileViewerSelecting([Switcher.shortcutsFile]) }
                    .buttonStyle(.plain)
                    .foregroundStyle(TN.dim)
                    .help(Switcher.shortcutsFile.path)
            }
            .font(TN.font(11))

            Text("Çakışma kontrolü: AeroSpace aerospace.toml, hyprmac hyprmac.conf, Amethyst varsayılanlar + amethyst.yml. "
                + "Amethyst'te tercih penceresinden değiştirdiğin kısayollar görünmez.")
                .font(TN.font(10)).foregroundStyle(TN.dim)
                .fixedSize(horizontal: false, vertical: true)

            Divider().overlay(TN.border)

            Text("Genel").font(TN.font(16, .bold)).foregroundStyle(TN.fg)
            Toggle("Login'de başlat (son seçili WM'i açar)",
                   isOn: Binding(get: { sw.loginEnabled }, set: { sw.setLogin($0) }))
                .toggleStyle(.switch)
                .controlSize(.small)
                .tint(TN.blue)
                .font(TN.font(12))
                .foregroundStyle(TN.fg)
        }
        .padding(20)
        .padding(.top, 8)
        .frame(width: 560)
        .background(TN.bg)
        .onAppear {
            sw.load()
            sw.scanConflicts()
        }
    }
}

struct ShortcutRow: View {
    @EnvironmentObject var sw: Switcher
    let id: String

    private var wm: WM? { sw.wms.first { $0.id == id } }
    private var isRecording: Bool { sw.recording == id }

    var body: some View {
        let current = sw.shortcut(id)
        let uses = current.flatMap { sw.wmBindings[$0] } ?? []

        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 10) {
                Text(wm?.letter ?? "∅")
                    .font(TN.font(14, .bold))
                    .foregroundStyle(TN.purple)
                    .frame(width: 26, height: 26)
                    .background(RoundedRectangle(cornerRadius: 6).fill(TN.card))
                Text(sw.actionName(id)).font(TN.font(13, .medium)).foregroundStyle(TN.fg)
                if let wm, !wm.installed {
                    Text("kurulu değil").font(TN.font(10)).foregroundStyle(TN.dim)
                }
                Spacer()

                Button {
                    isRecording ? sw.stopRecording() : sw.startRecording(id)
                } label: {
                    Text(isRecording ? "Tuşlara bas…" : current?.display ?? "Kısayol yok")
                        .font(TN.font(13, isRecording ? .regular : .semibold))
                        .foregroundStyle(isRecording ? TN.purple : (current == nil ? TN.dim : TN.fg))
                        .frame(minWidth: 130)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(RoundedRectangle(cornerRadius: 8).fill(isRecording ? TN.purple.opacity(0.15) : TN.card))
                        .overlay(RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(isRecording ? TN.purple : TN.border, lineWidth: isRecording ? 2 : 1))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Button {
                    sw.setShortcut(id, sw.defaultShortcut(id))
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                }
                .buttonStyle(.plain)
                .foregroundStyle(TN.dim)
                .help("Varsayılan: \(sw.defaultShortcut(id)?.display ?? "yok")")
                .disabled(current == sw.defaultShortcut(id))
                .opacity(current == sw.defaultShortcut(id) ? 0.3 : 1)
            }

            if isRecording, let hint = sw.recordHint {
                Text(hint).font(TN.font(11)).foregroundStyle(TN.red).padding(.leading, 36)
            }
            if !isRecording {
                if sw.unregistered.contains(id) {
                    warning("Kaydedilemedi: başka bir uygulama bu kısayolu kullanıyor", TN.red)
                }
                ForEach(uses, id: \.self) { use in
                    warning("Çakışma — \(use.wm): \(use.description)", Color(hex: 0xe0af68))
                }
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 10).fill(TN.card.opacity(0.5)))
    }

    private func warning(_ text: String, _ color: Color) -> some View {
        Label(text, systemImage: "exclamationmark.triangle.fill")
            .font(TN.font(11))
            .foregroundStyle(color)
            .padding(.leading, 36)
            .lineLimit(1)
            .truncationMode(.tail)
    }
}
