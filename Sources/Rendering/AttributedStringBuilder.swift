import AppKit
import Foundation

/// Custom NSAttributedString attribute keys for markdown syntax tracking
extension NSAttributedString.Key {
    /// The markdown syntax stack for this run (e.g., ["**", "*"] for bold-italic)
    static let markdownSyntax = NSAttributedString.Key("markdownSyntax")
    /// The MarkupElementType rawValue for this run
    static let markdownElementType = NSAttributedString.Key("markdownElementType")
    /// The link destination URL string
    static let linkDestination = NSAttributedString.Key("linkDestination")
}

/// Converts [StyledRun] into an NSAttributedString with visual + markdown tracking attributes
struct AttributedStringBuilder {

    static func build(from runs: [StyledRun]) -> NSAttributedString {
        let result = NSMutableAttributedString()
        for run in runs {
            let attrs = attributes(for: run)
            result.append(NSAttributedString(string: run.text, attributes: attrs))
        }
        return result
    }

    static func buildCodeBlock(text: String, style: ElementStyle) -> NSAttributedString {
        var attrs: [NSAttributedString.Key: Any] = [
            .font: style.resolvedNSFont,
            .markdownElementType: MarkupElementType.codeBlock.rawValue,
        ]
        if let fg = style.foregroundColor {
            attrs[.foregroundColor] = fg.nsColor
        }
        let paragraph = NSMutableParagraphStyle()
        if let spacing = style.lineSpacing, spacing > 0 {
            let font = style.resolvedNSFont
            let naturalHeight = font.ascender - font.descender + font.leading
            let desired = naturalHeight + spacing
            paragraph.minimumLineHeight = desired
            paragraph.maximumLineHeight = desired
            paragraph.lineSpacing = spacing
        }
        if let kern = style.letterSpacing {
            attrs[.kern] = kern
        }
        attrs[.paragraphStyle] = paragraph
        return NSAttributedString(string: text, attributes: attrs)
    }

    private static func attributes(for run: StyledRun) -> [NSAttributedString.Key: Any] {
        var attrs: [NSAttributedString.Key: Any] = [
            .font: run.style.resolvedNSFont,
            .markdownElementType: run.elementType.rawValue,
        ]

        // Foreground color
        if let fg = run.style.foregroundColor {
            attrs[.foregroundColor] = fg.nsColor
        }

        // Strikethrough visual
        if run.syntaxStack.contains("~~") {
            attrs[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
        }

        // Store syntax stack for round-trip reconstruction
        if !run.syntaxStack.isEmpty {
            attrs[.markdownSyntax] = run.syntaxStack
        }

        // Link-specific attributes
        if run.elementType == .link {
            if let dest = run.destination {
                attrs[.linkDestination] = dest
                attrs[.underlineStyle] = NSUnderlineStyle.single.rawValue
            }
        }

        // Letter spacing (kern)
        if let kern = run.style.letterSpacing {
            attrs[.kern] = kern
        }

        // Line spacing via paragraph style
        let paragraph = NSMutableParagraphStyle()
        if let spacing = run.style.lineSpacing, spacing > 0 {
            let font = run.style.resolvedNSFont
            let naturalHeight = font.ascender - font.descender + font.leading
            let desired = naturalHeight + spacing
            paragraph.minimumLineHeight = desired
            paragraph.maximumLineHeight = desired
            paragraph.lineSpacing = spacing
        }
        attrs[.paragraphStyle] = paragraph

        return attrs
    }
}
