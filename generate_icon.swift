#!/usr/bin/env swift
import AppKit

func drawIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let bounds = NSRect(x: 0, y: 0, width: size, height: size)
    let inset = size * 0.08
    let docRect = bounds.insetBy(dx: inset, dy: inset)
    let cornerRadius = size * 0.12

    // Shadow
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.3)
    shadow.shadowOffset = NSSize(width: 0, height: -size * 0.02)
    shadow.shadowBlurRadius = size * 0.06
    shadow.set()

    // Document background - white rounded rect
    let docPath = NSBezierPath(roundedRect: docRect, xRadius: cornerRadius, yRadius: cornerRadius)
    NSColor.white.setFill()
    docPath.fill()

    // Remove shadow for subsequent drawing
    let noShadow = NSShadow()
    noShadow.shadowColor = nil
    noShadow.set()

    // Gradient accent bar at top
    let barHeight = size * 0.18
    let barRect = NSRect(x: docRect.minX, y: docRect.maxY - barHeight, width: docRect.width, height: barHeight)
    let barPath = NSBezierPath()
    // Top-left and top-right rounded, bottom flat
    barPath.move(to: NSPoint(x: barRect.minX, y: barRect.minY))
    barPath.line(to: NSPoint(x: barRect.minX, y: barRect.maxY - cornerRadius))
    barPath.appendArc(from: NSPoint(x: barRect.minX, y: barRect.maxY),
                       to: NSPoint(x: barRect.minX + cornerRadius, y: barRect.maxY),
                       radius: cornerRadius)
    barPath.line(to: NSPoint(x: barRect.maxX - cornerRadius, y: barRect.maxY))
    barPath.appendArc(from: NSPoint(x: barRect.maxX, y: barRect.maxY),
                       to: NSPoint(x: barRect.maxX, y: barRect.maxY - cornerRadius),
                       radius: cornerRadius)
    barPath.line(to: NSPoint(x: barRect.maxX, y: barRect.minY))
    barPath.close()

    let gradient = NSGradient(starting: NSColor(red: 0.35, green: 0.5, blue: 0.95, alpha: 1.0),
                               ending: NSColor(red: 0.55, green: 0.35, blue: 0.9, alpha: 1.0))!
    gradient.draw(in: barPath, angle: 0)

    // Draw "M↓" markdown symbol in the bar
    let symbolSize = barHeight * 0.55
    let symbolFont = NSFont.systemFont(ofSize: symbolSize, weight: .bold)
    let symbolAttrs: [NSAttributedString.Key: Any] = [
        .font: symbolFont,
        .foregroundColor: NSColor.white,
    ]
    let symbolStr = "M\u{2193}" as NSString
    let symbolBounds = symbolStr.size(withAttributes: symbolAttrs)
    let symbolOrigin = NSPoint(
        x: barRect.midX - symbolBounds.width / 2,
        y: barRect.midY - symbolBounds.height / 2
    )
    symbolStr.draw(at: symbolOrigin, withAttributes: symbolAttrs)

    // Draw fake text lines in the document body
    let textAreaTop = barRect.minY - size * 0.06
    let lineHeight = size * 0.035
    let lineGap = size * 0.04
    let textInset = size * 0.14
    let lineWidths: [CGFloat] = [0.55, 0.7, 0.45, 0.65, 0.5, 0.7, 0.35, 0.6]

    for (i, widthFraction) in lineWidths.enumerated() {
        let y = textAreaTop - CGFloat(i) * (lineHeight + lineGap)
        if y < docRect.minY + size * 0.06 { break }

        let lineRect = NSRect(
            x: docRect.minX + textInset,
            y: y,
            width: (docRect.width - textInset * 2) * widthFraction,
            height: lineHeight
        )

        let color: NSColor
        if i == 0 {
            // "Heading" - thicker, darker
            color = NSColor(red: 0.2, green: 0.2, blue: 0.25, alpha: 0.8)
            let headingRect = NSRect(x: lineRect.minX, y: lineRect.minY, width: lineRect.width, height: lineHeight * 1.4)
            let headingPath = NSBezierPath(roundedRect: headingRect, xRadius: lineHeight * 0.3, yRadius: lineHeight * 0.3)
            color.setFill()
            headingPath.fill()
        } else {
            color = NSColor(red: 0.55, green: 0.55, blue: 0.6, alpha: 0.5)
            let linePath = NSBezierPath(roundedRect: lineRect, xRadius: lineHeight * 0.3, yRadius: lineHeight * 0.3)
            color.setFill()
            linePath.fill()
        }
    }

    // Subtle border on document
    NSColor(white: 0.85, alpha: 1.0).setStroke()
    docPath.lineWidth = size * 0.005
    docPath.stroke()

    image.unlockFocus()
    return image
}

// Generate iconset
let iconsetPath = "/Users/terrell/Documents/Code/markdown/AppIcon.iconset"
let fm = FileManager.default
try? fm.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

let sizes: [(name: String, size: CGFloat)] = [
    ("icon_16x16", 16),
    ("icon_16x16@2x", 32),
    ("icon_32x32", 32),
    ("icon_32x32@2x", 64),
    ("icon_128x128", 128),
    ("icon_128x128@2x", 256),
    ("icon_256x256", 256),
    ("icon_256x256@2x", 512),
    ("icon_512x512", 512),
    ("icon_512x512@2x", 1024),
]

for entry in sizes {
    let image = drawIcon(size: entry.size)
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:]) else {
        print("Failed to generate \(entry.name)")
        continue
    }
    let path = "\(iconsetPath)/\(entry.name).png"
    try png.write(to: URL(fileURLWithPath: path))
    print("Generated \(entry.name) (\(Int(entry.size))x\(Int(entry.size)))")
}

print("Done generating iconset")
