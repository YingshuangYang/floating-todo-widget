import AppKit

let outputURL = URL(fileURLWithPath: "/Users/yys/Documents/skills/docs/app-screenshot.png")
let fileManager = FileManager.default
try? fileManager.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)

let size = NSSize(width: 1440, height: 1080)
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

let shellRect = NSRect(x: 180, y: 130, width: 1080, height: 820)
let shellPath = roundedRect(shellRect, radius: 34)
color(255, 255, 255, 0.55).setFill()
shellPath.fill()
color(255, 255, 255, 0.75).setStroke()
shellPath.lineWidth = 2
shellPath.stroke()

let shadow = NSShadow()
shadow.shadowColor = color(0, 0, 0, 0.10)
shadow.shadowBlurRadius = 30
shadow.shadowOffset = NSSize(width: 0, height: -8)
shadow.set()
shellPath.fill()

drawText(
    "Daily to do list",
    in: NSRect(x: 235, y: 860, width: 500, height: 40),
    font: NSFont.systemFont(ofSize: 34, weight: .semibold),
    color: color(33, 36, 43)
)

drawText(
    "A calm space for today's priorities",
    in: NSRect(x: 238, y: 828, width: 320, height: 24),
    font: NSFont.systemFont(ofSize: 16, weight: .medium),
    color: color(109, 117, 132)
)

let pillRect = NSRect(x: 1070, y: 835, width: 92, height: 36)
let pill = roundedRect(pillRect, radius: 18)
color(224, 236, 255).setFill()
pill.fill()
drawText(
    "Today",
    in: NSRect(x: 1090, y: 844, width: 52, height: 18),
    font: NSFont.systemFont(ofSize: 13, weight: .semibold),
    color: color(82, 128, 227),
    alignment: .center
)

let leftCard = NSRect(x: 220, y: 185, width: 580, height: 610)
let leftPath = roundedRect(leftCard, radius: 28)
color(255, 255, 255, 0.72).setFill()
leftPath.fill()
color(0, 0, 0, 0.08).setStroke()
leftPath.lineWidth = 1
leftPath.stroke()

let rightCard = NSRect(x: 825, y: 185, width: 400, height: 610)
let rightPath = roundedRect(rightCard, radius: 28)
color(255, 255, 255, 0.82).setFill()
rightPath.fill()
color(0, 0, 0, 0.08).setStroke()
rightPath.lineWidth = 1
rightPath.stroke()

drawText("CHECK", in: NSRect(x: 250, y: 754, width: 70, height: 20), font: NSFont.systemFont(ofSize: 12, weight: .semibold), color: color(109, 117, 132))
drawText("NO.", in: NSRect(x: 345, y: 754, width: 60, height: 20), font: NSFont.systemFont(ofSize: 12, weight: .semibold), color: color(109, 117, 132))
drawText("TASK", in: NSRect(x: 435, y: 754, width: 120, height: 20), font: NSFont.systemFont(ofSize: 12, weight: .semibold), color: color(109, 117, 132))

let tasks = [
    ("No.1", "See a doctor", true),
    ("No.2", "PPT draft", false),
    ("No.3", "Snowflake video", false),
    ("No.4", "Apply 10 position", false),
    ("No.5", "PPT skills install", false),
    ("", "", false),
    ("", "", false),
    ("", "", false)
]

for (index, row) in tasks.enumerated() {
    let y = 706 - CGFloat(index) * 64
    let lineRect = NSRect(x: 240, y: y, width: 540, height: 1)
    color(0, 0, 0, 0.05).setFill()
    lineRect.fill()

    let circleRect = NSRect(x: 255, y: y - 29, width: 24, height: 24)
    let circle = NSBezierPath(ovalIn: circleRect)
    (row.2 ? color(190, 233, 207) : color(255, 255, 255, 0.9)).setFill()
    circle.fill()
    (row.2 ? color(97, 158, 117) : color(0, 0, 0, 0.10)).setStroke()
    circle.lineWidth = 1
    circle.stroke()

    if row.2 {
        let tick = NSBezierPath()
        tick.move(to: NSPoint(x: 262, y: y - 19))
        tick.line(to: NSPoint(x: 267, y: y - 24))
        tick.line(to: NSPoint(x: 274, y: y - 15))
        color(76, 145, 99).setStroke()
        tick.lineWidth = 2
        tick.lineCapStyle = .round
        tick.lineJoinStyle = .round
        tick.stroke()
    }

    drawText(row.0, in: NSRect(x: 336, y: y - 26, width: 60, height: 20), font: NSFont.systemFont(ofSize: 13, weight: .semibold), color: color(109, 117, 132))
    drawText(row.1, in: NSRect(x: 436, y: y - 27, width: 280, height: 20), font: NSFont.systemFont(ofSize: 16, weight: .medium), color: row.2 ? color(126, 133, 145) : color(33, 36, 43))

    if row.2 && !row.1.isEmpty {
        color(126, 133, 145, 0.8).setFill()
        NSRect(x: 436, y: y - 18, width: 132, height: 1.2).fill()
    }
}

drawText("Status", in: NSRect(x: 860, y: 748, width: 80, height: 20), font: NSFont.systemFont(ofSize: 12, weight: .semibold), color: color(109, 117, 132))
drawText("Keep the day moving", in: NSRect(x: 860, y: 710, width: 240, height: 32), font: NSFont.systemFont(ofSize: 28, weight: .semibold), color: color(33, 36, 43))

let center = NSPoint(x: 1025, y: 505)
let ringRadius: CGFloat = 110
let ringWidth: CGFloat = 22

let track = NSBezierPath()
track.appendArc(withCenter: center, radius: ringRadius, startAngle: 0, endAngle: 360)
color(255, 255, 255, 0.78).setStroke()
track.lineWidth = ringWidth
track.stroke()

let progress = NSBezierPath()
progress.appendArc(withCenter: center, radius: ringRadius, startAngle: 90, endAngle: -18, clockwise: true)
color(126, 201, 147).setStroke()
progress.lineWidth = ringWidth
progress.lineCapStyle = .round
progress.stroke()

let inner = NSBezierPath(ovalIn: NSRect(x: center.x - 54, y: center.y - 54, width: 108, height: 108))
color(255, 255, 255, 0.95).setFill()
inner.fill()

drawText("20%", in: NSRect(x: center.x - 42, y: center.y - 8, width: 84, height: 34), font: NSFont.systemFont(ofSize: 30, weight: .semibold), color: color(33, 36, 43), alignment: .center)
drawText("DONE", in: NSRect(x: center.x - 30, y: center.y - 32, width: 60, height: 18), font: NSFont.systemFont(ofSize: 11, weight: .semibold), color: color(109, 117, 132), alignment: .center)

let summary1 = roundedRect(NSRect(x: 855, y: 225, width: 168, height: 120), radius: 22)
color(255, 255, 255, 0.72).setFill()
summary1.fill()
let summary2 = roundedRect(NSRect(x: 1038, y: 225, width: 168, height: 120), radius: 22)
color(255, 255, 255, 0.72).setFill()
summary2.fill()

let dot1 = NSBezierPath(ovalIn: NSRect(x: 882, y: 315, width: 9, height: 9))
color(126, 201, 147).setFill()
dot1.fill()
drawText("Completed", in: NSRect(x: 882, y: 286, width: 90, height: 20), font: NSFont.systemFont(ofSize: 13, weight: .medium), color: color(109, 117, 132))
drawText("20%", in: NSRect(x: 882, y: 248, width: 90, height: 30), font: NSFont.systemFont(ofSize: 28, weight: .semibold), color: color(33, 36, 43))

let dot2 = NSBezierPath(ovalIn: NSRect(x: 1065, y: 315, width: 9, height: 9))
color(111, 158, 245).setFill()
dot2.fill()
drawText("Missing", in: NSRect(x: 1065, y: 286, width: 90, height: 20), font: NSFont.systemFont(ofSize: 13, weight: .medium), color: color(109, 117, 132))
drawText("80%", in: NSRect(x: 1065, y: 248, width: 90, height: 30), font: NSFont.systemFont(ofSize: 28, weight: .semibold), color: color(33, 36, 43))

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
    fatalError("Failed to export screenshot")
}

try png.write(to: outputURL)
