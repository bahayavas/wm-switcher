// Uygulama ikonunu çizer: swift tools/make-icon.swift <çıktı.png>  (1024x1024)
import AppKit

let size: CGFloat = 1024
let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon.png"
func c(_ hex: UInt32, _ a: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 0xff) / 255, green: CGFloat((hex >> 8) & 0xff) / 255,
            blue: CGFloat(hex & 0xff) / 255, alpha: a)
}

let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size), bitsPerSample: 8,
                           samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                           bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

// macOS ikon ızgarası: 824pt kare, 100pt kenar boşluğu
let body = NSRect(x: 100, y: 100, width: 824, height: 824)
let shape = NSBezierPath(roundedRect: body, xRadius: 185, yRadius: 185)
c(0x1a1b26).setFill()
shape.fill()
let grad = NSGradient(starting: c(0x7aa2f7), ending: c(0xbb9af7))!
let border = NSBezierPath(roundedRect: body.insetBy(dx: 8, dy: 8), xRadius: 178, yRadius: 178)
// Kenar gradyanı: kalın çizgiyi clip olarak kullan
NSGraphicsContext.saveGraphicsState()
let ctx = NSGraphicsContext.current!.cgContext
ctx.addPath(border.cgPath)
ctx.setLineWidth(16)
ctx.replacePathWithStrokedPath()
ctx.clip()
grad.draw(in: body, angle: -45)
NSGraphicsContext.restoreGraphicsState()

// Üç döşeme: solda büyük, sağda iki küçük (dwindle düzeni)
let pad: CGFloat = 70, gap: CGFloat = 34
let inner = body.insetBy(dx: pad + 40, dy: pad + 40)
let leftW = (inner.width - gap) * 0.55
let tiles = [
    (NSRect(x: inner.minX, y: inner.minY, width: leftW, height: inner.height), c(0x7aa2f7)),
    (NSRect(x: inner.minX + leftW + gap, y: inner.midY + gap / 2, width: inner.width - leftW - gap,
            height: inner.height / 2 - gap / 2), c(0xbb9af7)),
    (NSRect(x: inner.minX + leftW + gap, y: inner.minY, width: inner.width - leftW - gap,
            height: inner.height / 2 - gap / 2), c(0x7dcfff)),
]
for (r, col) in tiles {
    let p = NSBezierPath(roundedRect: r, xRadius: 44, yRadius: 44)
    col.withAlphaComponent(0.18).setFill()
    p.fill()
    col.setStroke()
    p.lineWidth = 14
    p.stroke()
}
// Ortada geçiş okları ⇄
let arrow = NSAttributedString(string: "⇄", attributes: [
    .font: NSFont.systemFont(ofSize: 230, weight: .bold),
    .foregroundColor: c(0xc0caf5),
])
let s = arrow.size()
arrow.draw(at: NSPoint(x: tiles[0].0.midX - s.width / 2, y: tiles[0].0.midY - s.height / 2))

try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
