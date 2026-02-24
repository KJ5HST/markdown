import SwiftUI
import AppKit

/// A Codable wrapper around SwiftUI Color
struct CodableColor: Codable, Equatable, Hashable {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double

    init(red: Double, green: Double, blue: Double, alpha: Double = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    init(color: Color) {
        if let converted = NSColor(color).usingColorSpace(.sRGB) {
            self.red = Double(converted.redComponent)
            self.green = Double(converted.greenComponent)
            self.blue = Double(converted.blueComponent)
            self.alpha = Double(converted.alphaComponent)
        } else {
            self.red = 0
            self.green = 0
            self.blue = 0
            self.alpha = 1
        }
    }

    init(nsColor: NSColor) {
        if let converted = nsColor.usingColorSpace(.sRGB) {
            self.red = Double(converted.redComponent)
            self.green = Double(converted.greenComponent)
            self.blue = Double(converted.blueComponent)
            self.alpha = Double(converted.alphaComponent)
        } else {
            self.red = 0
            self.green = 0
            self.blue = 0
            self.alpha = 1
        }
    }

    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: alpha)
    }

    var nsColor: NSColor {
        NSColor(red: red, green: green, blue: blue, alpha: alpha)
    }

    // Common colors
    static let black = CodableColor(red: 0, green: 0, blue: 0)
    static let white = CodableColor(red: 1, green: 1, blue: 1)
    static let gray = CodableColor(red: 0.5, green: 0.5, blue: 0.5)
    static let blue = CodableColor(red: 0.0, green: 0.478, blue: 1.0)
    static let clear = CodableColor(red: 0, green: 0, blue: 0, alpha: 0)
}
