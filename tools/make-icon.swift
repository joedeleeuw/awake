// Draws Awake's app icon: a white glass squircle with a black cup.
// The cup is drawn by hand (Apple's license doesn't allow SF Symbols in app icons).
// Usage: swift tools/make-icon.swift   (writes Assets.xcassets/AppIcon.appiconset)

import AppKit

let outDir = URL(fileURLWithPath: "Assets.xcassets/AppIcon.appiconset", isDirectory: true)
try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

func drawIcon(_ s: CGFloat) {
    // Apple's macOS grid: 824pt artwork centered in a 1024pt canvas.
    let inset = s * 100 / 1024
    let plate = CGRect(x: inset, y: inset, width: s - 2 * inset, height: s - 2 * inset)
    let platePath = NSBezierPath(roundedRect: plate, xRadius: plate.width * 0.225, yRadius: plate.width * 0.225)

    // Soft shadow under the plate.
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.22)
    shadow.shadowBlurRadius = s * 0.025
    shadow.shadowOffset = NSSize(width: 0, height: -s * 0.010)
    shadow.set()
    NSColor.white.setFill()
    platePath.fill()
    NSGraphicsContext.restoreGraphicsState()

    // White glass: bright at the top, the faintest grey at the bottom.
    NSGradient(colors: [NSColor(white: 1.0, alpha: 1), NSColor(white: 0.985, alpha: 1), NSColor(white: 0.925, alpha: 1)],
               atLocations: [0, 0.45, 1], colorSpace: .deviceGray)!
        .draw(in: platePath, angle: -90)

    // Thin highlight along the top edge, hairline around the plate.
    NSGraphicsContext.saveGraphicsState()
    platePath.addClip()
    let rim = NSBezierPath(roundedRect: plate.insetBy(dx: s * 0.004, dy: s * 0.004),
                           xRadius: plate.width * 0.22, yRadius: plate.width * 0.22)
    rim.lineWidth = s * 0.006
    NSColor.white.withAlphaComponent(0.9).setStroke()
    rim.stroke()
    NSGraphicsContext.restoreGraphicsState()
    platePath.lineWidth = max(1, s / 512)
    NSColor(white: 0, alpha: 0.08).setStroke()
    platePath.stroke()

    // The cup, in near-black.
    let ink = NSColor(white: 0.09, alpha: 1)
    ink.set()
    let cx = s * 0.47                     // nudged left to balance the handle
    let w = s * 0.34, h = s * 0.25
    let top = s * 0.635, bottom = top - h
    let left = cx - w / 2, right = cx + w / 2
    let taper = s * 0.018, r = s * 0.085

    // Handle first, so the body covers its inner half.
    let handle = NSBezierPath(ovalIn: CGRect(x: right - s * 0.075, y: bottom + h * 0.30,
                                             width: s * 0.15, height: s * 0.135))
    handle.lineWidth = s * 0.034
    handle.stroke()

    let body = NSBezierPath()
    body.move(to: CGPoint(x: left, y: top))
    body.line(to: CGPoint(x: right, y: top))
    body.line(to: CGPoint(x: right - taper * 0.4, y: bottom + r))
    body.curve(to: CGPoint(x: right - taper - r, y: bottom),
               controlPoint1: CGPoint(x: right - taper * 0.6, y: bottom + r * 0.35),
               controlPoint2: CGPoint(x: right - taper - r * 0.45, y: bottom))
    body.line(to: CGPoint(x: left + taper + r, y: bottom))
    body.curve(to: CGPoint(x: left + taper * 0.4, y: bottom + r),
               controlPoint1: CGPoint(x: left + taper + r * 0.45, y: bottom),
               controlPoint2: CGPoint(x: left + taper * 0.6, y: bottom + r * 0.35))
    body.close()
    body.fill()

    // Saucer.
    let saucerH = s * 0.034
    let saucer = NSBezierPath(roundedRect: CGRect(x: cx - s * 0.26 + s * 0.015, y: bottom - s * 0.062,
                                                  width: s * 0.52, height: saucerH),
                              xRadius: saucerH / 2, yRadius: saucerH / 2)
    saucer.fill()
}

func png(pixels: Int) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: pixels, height: pixels)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSGraphicsContext.current?.imageInterpolation = .high
    drawIcon(CGFloat(pixels))
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

var images: [[String: String]] = []
for points in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let name = "icon_\(points)x\(points)\(scale == 2 ? "@2x" : "").png"
        try png(pixels: points * scale).write(to: outDir.appendingPathComponent(name))
        images.append(["idiom": "mac", "size": "\(points)x\(points)", "scale": "\(scale)x", "filename": name])
    }
}
let contents: [String: Any] = ["images": images, "info": ["author": "xcode", "version": 1]]
try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
    .write(to: outDir.appendingPathComponent("Contents.json"))
try #"{"info":{"author":"xcode","version":1}}"#.data(using: .utf8)!
    .write(to: outDir.deletingLastPathComponent().appendingPathComponent("Contents.json"))
print("Wrote \(images.count) icon sizes to \(outDir.path)")
