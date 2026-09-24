// Draws Tik's app icons (the default one and the alternates) plus the small
// previews shown in Settings, straight into the asset catalog.
//
// Usage (from the repo root):  swift Scripts/make-icons.swift

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

struct RGB {
    var r: CGFloat, g: CGFloat, b: CGFloat

    init(_ hex: UInt32) {
        r = CGFloat((hex >> 16) & 0xFF) / 255
        g = CGFloat((hex >> 8) & 0xFF) / 255
        b = CGFloat(hex & 0xFF) / 255
    }
}

struct IconStyle {
    let name: String
    let top: RGB
    let bottom: RGB
    let glowA: RGB
    let glowB: RGB
    let plateAlpha: CGFloat
    let check: RGB
}

let styles = [
    IconStyle(name: "AppIcon", top: RGB(0x62D0FF), bottom: RGB(0x0A5BFF),
              glowA: RGB(0xB8F1FF), glowB: RGB(0x7B4DFF), plateAlpha: 0.20, check: RGB(0xFFFFFF)),
    IconStyle(name: "AppIcon-Midnight", top: RGB(0x1C1F2E), bottom: RGB(0x050508),
              glowA: RGB(0x2F6BFF), glowB: RGB(0x8A3DFF), plateAlpha: 0.09, check: RGB(0xFFFFFF)),
    IconStyle(name: "AppIcon-Light", top: RGB(0xFFFFFF), bottom: RGB(0xDDE5F2),
              glowA: RGB(0xFFFFFF), glowB: RGB(0x9CC3FF), plateAlpha: 0.55, check: RGB(0x0A6CFF)),
    IconStyle(name: "AppIcon-Mint", top: RGB(0x7CF5C4), bottom: RGB(0x00A88E),
              glowA: RGB(0xE0FFF4), glowB: RGB(0x00B7D4), plateAlpha: 0.20, check: RGB(0xFFFFFF)),
    IconStyle(name: "AppIcon-Purple", top: RGB(0xC58BFF), bottom: RGB(0x4B18D6),
              glowA: RGB(0xF2DEFF), glowB: RGB(0xFF5DB1), plateAlpha: 0.20, check: RGB(0xFFFFFF)),
    IconStyle(name: "AppIcon-Sunset", top: RGB(0xFFC26B), bottom: RGB(0xF2395F),
              glowA: RGB(0xFFF1C9), glowB: RGB(0xB5179E), plateAlpha: 0.20, check: RGB(0xFFFFFF)),
]

let space = CGColorSpace(name: CGColorSpace.sRGB)!
let white = RGB(0xFFFFFF)
let black = RGB(0x000000)

func cg(_ c: RGB, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(colorSpace: space, components: [c.r, c.g, c.b, alpha])!
}

func gradient(_ stops: [(RGB, CGFloat)], locations: [CGFloat]) -> CGGradient {
    CGGradient(colorsSpace: space, colors: stops.map { cg($0.0, $0.1) } as CFArray, locations: locations)!
}

/// Draws one icon. Everything is laid out on a 1024 x 1024 grid and scaled.
func render(_ style: IconStyle, size: Int) -> CGImage {
    let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
                        space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    ctx.scaleBy(x: CGFloat(size) / 1024, y: CGFloat(size) / 1024)

    // Background: a diagonal gradient from the top-left to the bottom-right.
    ctx.drawLinearGradient(gradient([(style.top, 1), (style.bottom, 1)], locations: [0, 1]),
                           start: CGPoint(x: 0, y: 1024), end: CGPoint(x: 1024, y: 0), options: [])

    // Two soft glows give the glass something to sit on.
    func glow(_ color: RGB, alpha: CGFloat, at point: CGPoint, radius: CGFloat) {
        ctx.drawRadialGradient(gradient([(color, alpha), (color, 0)], locations: [0, 1]),
                               startCenter: point, startRadius: 0, endCenter: point, endRadius: radius, options: [])
    }
    glow(style.glowA, alpha: 0.55, at: CGPoint(x: 190, y: 880), radius: 640)
    glow(style.glowB, alpha: 0.50, at: CGPoint(x: 900, y: 110), radius: 660)

    // The glass plate: shadow + fill, a highlight on top, and a thin rim.
    let plateRect = CGRect(x: 212, y: 212, width: 600, height: 600)
    let plate = CGPath(roundedRect: plateRect, cornerWidth: 172, cornerHeight: 172, transform: nil)

    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -26), blur: 64, color: cg(black, 0.22))
    ctx.addPath(plate)
    ctx.setFillColor(cg(white, style.plateAlpha))
    ctx.fillPath()
    ctx.restoreGState()

    ctx.saveGState()
    ctx.addPath(plate)
    ctx.clip()
    ctx.drawLinearGradient(gradient([(white, 0.40), (white, 0)], locations: [0, 1]),
                           start: CGPoint(x: 0, y: plateRect.maxY), end: CGPoint(x: 0, y: plateRect.midY + 40),
                           options: [])
    ctx.restoreGState()

    ctx.saveGState()
    ctx.addPath(plate)
    ctx.setLineWidth(7)
    ctx.replacePathWithStrokedPath()
    ctx.clip()
    ctx.drawLinearGradient(gradient([(white, 0.85), (white, 0.10), (white, 0.50)], locations: [0, 0.55, 1]),
                           start: CGPoint(x: plateRect.minX, y: plateRect.maxY),
                           end: CGPoint(x: plateRect.maxX, y: plateRect.minY), options: [])
    ctx.restoreGState()

    // The check mark.
    let check = CGMutablePath()
    check.move(to: CGPoint(x: 366, y: 520))
    check.addLine(to: CGPoint(x: 462, y: 424))
    check.addLine(to: CGPoint(x: 662, y: 624))

    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -10), blur: 22, color: cg(black, 0.20))
    ctx.addPath(check)
    ctx.setLineWidth(86)
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)
    ctx.setStrokeColor(cg(style.check))
    ctx.strokePath()
    ctx.restoreGState()

    return ctx.makeImage()!
}

func writePNG(_ image: CGImage, to url: URL) {
    let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, image, nil)
    CGImageDestinationFinalize(destination)
}

func writeJSON(_ object: Any, to url: URL) throws {
    let data = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
    try data.write(to: url)
}

let catalog = URL(fileURLWithPath: "Tik/Resources/Assets.xcassets")
let info = ["author": "xcode", "version": 1] as [String: Any]
let fileManager = FileManager.default

for style in styles {
    // The icon itself (a single 1024 px image is enough on modern iOS).
    let iconSet = catalog.appendingPathComponent("\(style.name).appiconset")
    try fileManager.createDirectory(at: iconSet, withIntermediateDirectories: true)
    writePNG(render(style, size: 1024), to: iconSet.appendingPathComponent("\(style.name).png"))
    try writeJSON([
        "images": [["filename": "\(style.name).png", "idiom": "universal", "platform": "ios", "size": "1024x1024"]],
        "info": info,
    ], to: iconSet.appendingPathComponent("Contents.json"))

    // A small copy for the icon picker in Settings.
    let previewSet = catalog.appendingPathComponent("IconPreview-\(style.name).imageset")
    try fileManager.createDirectory(at: previewSet, withIntermediateDirectories: true)
    writePNG(render(style, size: 240), to: previewSet.appendingPathComponent("IconPreview-\(style.name).png"))
    try writeJSON([
        "images": [["filename": "IconPreview-\(style.name).png", "idiom": "universal"]],
        "info": info,
    ], to: previewSet.appendingPathComponent("Contents.json"))

    print("Wrote \(style.name)")
}
