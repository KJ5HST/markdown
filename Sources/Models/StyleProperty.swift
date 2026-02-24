import SwiftUI
import AppKit

/// Per-element styling configuration. All properties are optional — nil means inherit/use default.
struct ElementStyle: Codable, Equatable {
    var fontFamily: String?
    var fontSize: CGFloat?
    var fontWeight: FontWeight?
    var isItalic: Bool?
    var letterSpacing: CGFloat?
    var foregroundColor: CodableColor?
    var backgroundColor: CodableColor?
    var paddingTop: CGFloat?
    var paddingBottom: CGFloat?
    var paddingLeading: CGFloat?
    var paddingTrailing: CGFloat?
    var lineSpacing: CGFloat?
    var borderColor: CodableColor?
    var borderWidth: CGFloat?
    var cornerRadius: CGFloat?
    var isMonospaced: Bool?

    static let empty = ElementStyle()

    /// Merge another style on top of this one. Non-nil values in `other` override.
    func merging(with other: ElementStyle) -> ElementStyle {
        ElementStyle(
            fontFamily: other.fontFamily ?? fontFamily,
            fontSize: other.fontSize ?? fontSize,
            fontWeight: other.fontWeight ?? fontWeight,
            isItalic: other.isItalic ?? isItalic,
            letterSpacing: other.letterSpacing ?? letterSpacing,
            foregroundColor: other.foregroundColor ?? foregroundColor,
            backgroundColor: other.backgroundColor ?? backgroundColor,
            paddingTop: other.paddingTop ?? paddingTop,
            paddingBottom: other.paddingBottom ?? paddingBottom,
            paddingLeading: other.paddingLeading ?? paddingLeading,
            paddingTrailing: other.paddingTrailing ?? paddingTrailing,
            lineSpacing: other.lineSpacing ?? lineSpacing,
            borderColor: other.borderColor ?? borderColor,
            borderWidth: other.borderWidth ?? borderWidth,
            cornerRadius: other.cornerRadius ?? cornerRadius,
            isMonospaced: other.isMonospaced ?? isMonospaced
        )
    }

    /// Return a copy with values clamped to safe ranges
    func validated() -> ElementStyle {
        var s = self
        if let v = s.fontSize { s.fontSize = min(max(v, 1), 200) }
        if let v = s.paddingTop { s.paddingTop = min(max(v, 0), 200) }
        if let v = s.paddingBottom { s.paddingBottom = min(max(v, 0), 200) }
        if let v = s.paddingLeading { s.paddingLeading = min(max(v, 0), 200) }
        if let v = s.paddingTrailing { s.paddingTrailing = min(max(v, 0), 200) }
        if let v = s.lineSpacing { s.lineSpacing = min(max(v, 0), 100) }
        if let v = s.borderWidth { s.borderWidth = min(max(v, 0), 50) }
        if let v = s.cornerRadius { s.cornerRadius = min(max(v, 0), 100) }
        if let v = s.letterSpacing { s.letterSpacing = min(max(v, -10), 50) }
        return s
    }

    /// Resolve font from style properties
    var resolvedFont: Font {
        var font: Font
        let size = fontSize ?? 14

        if isMonospaced == true {
            font = .system(size: size, design: .monospaced)
        } else if let family = fontFamily {
            font = .custom(family, size: size)
        } else {
            font = .system(size: size)
        }

        if let weight = fontWeight {
            font = font.weight(weight.swiftUIWeight)
        }

        if isItalic == true {
            font = font.italic()
        }

        return font
    }

    /// Resolve NSFont from style properties (for NSTextView / NSAttributedString)
    var resolvedNSFont: NSFont {
        let size = fontSize ?? 14

        var nsFont: NSFont
        if isMonospaced == true {
            nsFont = NSFont.monospacedSystemFont(ofSize: size, weight: fontWeight?.nsWeight ?? .regular)
        } else if let family = fontFamily, let customFont = NSFont(name: family, size: size) {
            nsFont = customFont
        } else {
            nsFont = NSFont.systemFont(ofSize: size, weight: fontWeight?.nsWeight ?? .regular)
        }

        if isItalic == true {
            var traits = nsFont.fontDescriptor.symbolicTraits
            traits.insert(.italic)
            let italicDescriptor = nsFont.fontDescriptor.withSymbolicTraits(traits)
            nsFont = NSFont(descriptor: italicDescriptor, size: size) ?? nsFont
        }

        return nsFont
    }
}

/// Codable font weight
enum FontWeight: String, Codable, CaseIterable, Equatable {
    case ultraLight
    case thin
    case light
    case regular
    case medium
    case semibold
    case bold
    case heavy
    case black

    var swiftUIWeight: Font.Weight {
        switch self {
        case .ultraLight: return .ultraLight
        case .thin: return .thin
        case .light: return .light
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        case .heavy: return .heavy
        case .black: return .black
        }
    }

    var nsWeight: NSFont.Weight {
        switch self {
        case .ultraLight: return .ultraLight
        case .thin: return .thin
        case .light: return .light
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        case .heavy: return .heavy
        case .black: return .black
        }
    }

    var displayName: String {
        rawValue.capitalized
    }
}
