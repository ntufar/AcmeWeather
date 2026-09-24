#!/usr/bin/env swift
// Renders the 1024×1024 app icon: a peach sun rising behind a storm cloud
// with a lightning bolt, on a deep navy-to-violet sky.
//
// Usage: swift scripts/generate_app_icon.swift
import AppKit

let size = 1024.0
let output = "AcmeWeather/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"

let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size),
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
)!
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
let ctx = NSGraphicsContext.current!.cgContext

func color(_ r: Double, _ g: Double, _ b: Double, _ a: Double = 1) -> CGColor {
    CGColor(red: r, green: g, blue: b, alpha: a)
}

// Sky
let sky = CGGradient(colorsSpace: nil, colors: [
    color(0.04, 0.10, 0.24), color(0.20, 0.13, 0.36), color(0.55, 0.25, 0.35),
] as CFArray, locations: [0, 0.6, 1])!
ctx.drawLinearGradient(sky, start: CGPoint(x: 0, y: size), end: CGPoint(x: 0, y: 0), options: [])

// Sun glow + disc (the "peach")
let sunCenter = CGPoint(x: size * 0.62, y: size * 0.58)
let glow = CGGradient(colorsSpace: nil, colors: [color(1, 0.62, 0.40, 0.75), color(1, 0.55, 0.38, 0)] as CFArray, locations: [0, 1])!
ctx.drawRadialGradient(glow, startCenter: sunCenter, startRadius: 0, endCenter: sunCenter, endRadius: size * 0.48, options: [])
let sunDisc = CGGradient(colorsSpace: nil, colors: [color(1, 0.84, 0.62), color(1, 0.52, 0.36)] as CFArray, locations: [0, 1])!
ctx.saveGState()
ctx.addEllipse(in: CGRect(x: sunCenter.x - 230, y: sunCenter.y - 230, width: 460, height: 460))
ctx.clip()
ctx.drawLinearGradient(sunDisc, start: CGPoint(x: sunCenter.x, y: sunCenter.y + 230), end: CGPoint(x: sunCenter.x, y: sunCenter.y - 230), options: [])
ctx.restoreGState()

// Leaf on the peach
ctx.setFillColor(color(0.30, 0.72, 0.45))
ctx.saveGState()
ctx.translateBy(x: sunCenter.x + 60, y: sunCenter.y + 240)
ctx.rotate(by: -0.6)
ctx.addEllipse(in: CGRect(x: -40, y: -90, width: 80, height: 180))
ctx.fillPath()
ctx.restoreGState()

// Cloud
ctx.setShadow(offset: CGSize(width: 0, height: -12), blur: 40, color: color(0, 0, 0, 0.35))
ctx.setFillColor(color(0.93, 0.95, 1.0))
for (x, y, r) in [(300.0, 420.0, 150.0), (470.0, 470.0, 190.0), (640.0, 410.0, 140.0), (210.0, 350.0, 100.0), (760.0, 350.0, 95.0)] {
    ctx.addEllipse(in: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
}
ctx.addRect(CGRect(x: 210, y: 255, width: 550, height: 150))
ctx.fillPath()
ctx.setShadow(offset: .zero, blur: 0, color: nil)

// Lightning bolt
let bolt = CGMutablePath()
bolt.addLines(between: [
    CGPoint(x: 520, y: 380), CGPoint(x: 405, y: 210), CGPoint(x: 480, y: 210),
    CGPoint(x: 425, y: 80), CGPoint(x: 595, y: 265), CGPoint(x: 515, y: 265), CGPoint(x: 580, y: 380),
])
bolt.closeSubpath()
ctx.setShadow(offset: .zero, blur: 30, color: color(1, 0.85, 0.2, 0.9))
ctx.setFillColor(color(1, 0.84, 0.18))
ctx.addPath(bolt)
ctx.fillPath()

NSGraphicsContext.current = nil
let png = rep.representation(using: .png, properties: [:])!
try! png.write(to: URL(fileURLWithPath: output))
print("Wrote \(output)")
