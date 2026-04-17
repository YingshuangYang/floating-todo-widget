import AppKit

let outputURL = URL(fileURLWithPath: "/Users/yys/Documents/skills/docs/mini-app-screenshot.png")
let fileManager = FileManager.default
try? fileManager.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)

let size = NSSize(width: 720, height: 720)
let image = NSImage(size: size)

func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1.0) -> NSColor {
    NSColor(calibratedRed: r / 255, green: g / 255, blue: b / 255, alpha: a)
}

func roundedRect(_ rect: NSRect, radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
}

func drawText(_ text: String, in rect: NSRect, font: NSFont, color: NSColor, alignment: NSTextAlignment = .left) {
    let style = NSMutableParagraphStyle()
    style.alignment = alignment
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: color,
        .paragraphStyle: style
    ]
    text.draw(in: rect, withAttributes: attrs)
}

image.lockFocus()

let background = NSGradient(colors: [
    color(243, 245, 249),
    color(231, 236, 244)
])!
background.draw(in: NSRect(origin: .zero, size: size), angle: 90)

let widgetRect = NSRect(x: 82, y: 88, width: 556, height: 544)
let widgetPath = roundedRect(widgetRect, radius: 34)
color(255, 255, 255, 0.58).setFill()
widgetPath.fill()
color(255, 255, 255, 0.78).setStroke()
widgetPath.lineWidth = 2
widgetPath.stroke()

let shadow = NSShadow()
shadow.shadowColor = color(0, 0, 0, 0.10)
shadow.shadowBlurRadius = 24
shadow.shadowOffset = NSSize(width: 0, height: -6)
shadow.set()
widgetPath.fill()

drawText(
    "Today",
    in: NSRect(x: 120, y: 555, width: 180, height: 40),
    font: NSFont.systemFont(ofSize: 34, weight: .semibold),
    color: color(33, 36, 43)
)

drawText(
    "Apr 17, 2026",
    in: NSRect(x: 121, y: 520, width: 180, height: 22),
    font: NSFont.systemFont(ofSize: 16, weight: .medium),
    color: color(109, 117, 132)
)

drawText(
    "20%",
    in: NSRect(x: 470, y: 555, width: 90, height: 34),
    font: NSFont.systemFont(ofSize: 30, weight: .semibold),
    color: color(33, 36, 43),
    alignment: .right
)

drawText(
    "DONE",
    in: NSRect(x: 485, y: 524, width: 75, height: 18),
    font: NSFont.systemFont(ofSize: 11, weight: .semibold),
    color: color(109, 117, 132),
    alignment: .right
)

let rows = [
    ("No.1", "PPT draft", false),
    ("No.2", "Orthodox Easter", false),
    ("No.3", "Seminar at 10:00", false)
]

for (index, row) in rows.enumerated() {
    let y = 435 - CGFloat(index) * 88
    let rowRect = NSRect(x: 116, y: y, width: 490, height: 64)
    let rowPath = roundedRect(rowRect, radius: 22)
    color(255, 255, 255, 0.72).setFill()
    rowPath.fill()

    let checkRect = NSRect(x: 136, y: y + 18, width: 28, height: 28)
    let checkPath = NSBezierPath(ovalIn: checkRect)
    color(255, 255, 255, 0.84).setFill()
    checkPath.fill()
    color(0, 0, 0, 0.10).setStroke()
    checkPath.lineWidth = 1
    checkPath.stroke()

    drawText(
        row.0,
        in: NSRect(x: 186, y: y + 23, width: 56, height: 18),
        font: NSFont.systemFont(ofSize: 13, weight: .semibold),
        color: color(109, 117, 132)
    )

    drawText(
        row.1,
        in: NSRect(x: 256, y: y + 20, width: 280, height: 24),
        font: NSFont.systemFont(ofSize: 20, weight: .medium),
        color: color(33, 36, 43)
    )
}

let footerIcon = NSBezierPath()
footerIcon.move(to: NSPoint(x: 118, y: 122))
footerIcon.line(to: NSPoint(x: 118, y: 133))
footerIcon.line(to: NSPoint(x: 122, y: 133))
footerIcon.move(to: NSPoint(x: 118, y: 128))
footerIcon.line(to: NSPoint(x: 126, y: 128))
footerIcon.move(to: NSPoint(x: 118, y: 122))
footerIcon.line(to: NSPoint(x: 126, y: 122))
color(109, 117, 132).setStroke()
footerIcon.lineWidth = 1.4
footerIcon.lineCapStyle = .round
footerIcon.stroke()

drawText(
    "Daily list",
    in: NSRect(x: 140, y: 116, width: 120, height: 18),
    font: NSFont.systemFont(ofSize: 14, weight: .medium),
    color: color(109, 117, 132)
)

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
    fatalError("Failed to export mini screenshot")
}

try png.write(to: outputURL)
