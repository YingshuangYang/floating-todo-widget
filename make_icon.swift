import AppKit
import Foundation

let root = URL(fileURLWithPath: "/Users/yys/Documents/skills")
let iconsetURL = root.appendingPathComponent("AppIcon.iconset", isDirectory: true)
let fileManager = FileManager.default

try? fileManager.removeItem(at: iconsetURL)
try fileManager.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

let entries: [(String, CGFloat)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

func drawIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    let radius = size * 0.225
    let bgPath = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)

    let gradient = NSGradient(
        colors: [
            NSColor(calibratedRed: 0.93, green: 0.96, blue: 1.0, alpha: 1.0),
            NSColor(calibratedRed: 0.85, green: 0.90, blue: 0.99, alpha: 1.0)
        ]
    )!
    gradient.draw(in: bgPath, angle: 90)

    NSColor(calibratedWhite: 1.0, alpha: 0.38).setStroke()
    bgPath.lineWidth = max(2, size * 0.015)
    bgPath.stroke()

    let cardRect = NSRect(
        x: size * 0.2,
        y: size * 0.16,
        width: size * 0.6,
        height: size * 0.68
    )
    let cardPath = NSBezierPath(roundedRect: cardRect, xRadius: size * 0.08, yRadius: size * 0.08)
    NSColor.white.setFill()
    cardPath.fill()

    NSColor(calibratedRed: 0.62, green: 0.73, blue: 0.94, alpha: 0.22).setStroke()
    cardPath.lineWidth = max(1.5, size * 0.01)
    cardPath.stroke()

    let clipRect = NSRect(
        x: size * 0.39,
        y: size * 0.75,
        width: size * 0.22,
        height: size * 0.08
    )
    let clipPath = NSBezierPath(roundedRect: clipRect, xRadius: size * 0.03, yRadius: size * 0.03)
    NSColor(calibratedRed: 0.28, green: 0.53, blue: 0.94, alpha: 1.0).setFill()
    clipPath.fill()

    let left = size * 0.3
    let right = size * 0.68
    let lineHeight = size * 0.035
    let round = lineHeight / 2
    let rows: [CGFloat] = [0.61, 0.49, 0.37]

    for (idx, yFactor) in rows.enumerated() {
        let y = size * yFactor
        let checkCenter = NSPoint(x: size * 0.34, y: y)
        let checkRadius = size * 0.035
        let checkBg = NSBezierPath(ovalIn: NSRect(
            x: checkCenter.x - checkRadius,
            y: checkCenter.y - checkRadius,
            width: checkRadius * 2,
            height: checkRadius * 2
        ))

        if idx == 0 {
            NSColor(calibratedRed: 0.41, green: 0.77, blue: 0.50, alpha: 1.0).setFill()
            checkBg.fill()

            let tick = NSBezierPath()
            tick.move(to: NSPoint(x: size * 0.326, y: y - size * 0.004))
            tick.line(to: NSPoint(x: size * 0.338, y: y - size * 0.018))
            tick.line(to: NSPoint(x: size * 0.362, y: y + size * 0.016))
            NSColor.white.setStroke()
            tick.lineWidth = max(1.8, size * 0.012)
            tick.lineCapStyle = .round
            tick.lineJoinStyle = .round
            tick.stroke()
        } else {
            NSColor(calibratedRed: 0.86, green: 0.90, blue: 0.96, alpha: 1.0).setFill()
            checkBg.fill()
        }

        let lineRect = NSRect(x: left, y: y - lineHeight / 2, width: right - left, height: lineHeight)
        let linePath = NSBezierPath(roundedRect: lineRect, xRadius: round, yRadius: round)
        let color = idx == 0
            ? NSColor(calibratedRed: 0.73, green: 0.78, blue: 0.84, alpha: 1.0)
            : NSColor(calibratedRed: 0.46, green: 0.60, blue: 0.90, alpha: idx == 1 ? 0.92 : 0.72)
        color.setFill()
        linePath.fill()
    }

    let sheen = NSBezierPath(roundedRect: NSRect(x: size * 0.22, y: size * 0.48, width: size * 0.12, height: size * 0.24), xRadius: size * 0.05, yRadius: size * 0.05)
    NSColor(calibratedWhite: 1.0, alpha: 0.15).setFill()
    sheen.fill()

    image.unlockFocus()
    return image
}

func writePNG(_ image: NSImage, to url: URL) throws {
    guard let tiffData = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let pngData = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "IconWriter", code: 1)
    }

    try pngData.write(to: url)
}

for (filename, size) in entries {
    let image = drawIcon(size: size)
    try writePNG(image, to: iconsetURL.appendingPathComponent(filename))
}
