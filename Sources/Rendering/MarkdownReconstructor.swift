import AppKit
import Foundation

/// Converts an edited NSAttributedString back into a markdown string,
/// using custom attributes (.markdownSyntax, .markdownElementType, .linkDestination)
/// to reconstruct the proper markdown syntax.
struct MarkdownReconstructor {

    /// Reconstruct markdown from an edited attributed string and its block element type.
    static func reconstruct(_ attributedString: NSAttributedString, elementType: MarkupElementType, language: String? = nil) -> String {
        switch elementType {
        case .codeBlock:
            return reconstructCodeBlock(attributedString, language: language)
        default:
            let inlineMarkdown = reconstructInlines(attributedString)
            return addBlockPrefix(inlineMarkdown, elementType: elementType)
        }
    }

    // MARK: - Block Prefix

    private static func addBlockPrefix(_ text: String, elementType: MarkupElementType) -> String {
        switch elementType {
        case .heading1: return "# \(text)"
        case .heading2: return "## \(text)"
        case .heading3: return "### \(text)"
        case .heading4: return "#### \(text)"
        case .heading5: return "##### \(text)"
        case .heading6: return "###### \(text)"
        case .paragraph, .text: return text
        default: return text
        }
    }

    // MARK: - Code Block

    private static func reconstructCodeBlock(_ attributedString: NSAttributedString, language: String?) -> String {
        let code = attributedString.string
        let fence = "```"
        let langTag = language ?? ""
        return "\(fence)\(langTag)\n\(code)\(fence)"
    }

    // MARK: - Inline Reconstruction

    private static func reconstructInlines(_ attributedString: NSAttributedString) -> String {
        var result = ""
        let fullRange = NSRange(location: 0, length: attributedString.length)

        attributedString.enumerateAttributes(in: fullRange, options: []) { attrs, range, _ in
            let text = (attributedString.string as NSString).substring(with: range)

            // Read syntax stack (supports both [String] and legacy String)
            let syntaxStack: [String]
            if let stack = attrs[.markdownSyntax] as? [String] {
                syntaxStack = stack
            } else if let single = attrs[.markdownSyntax] as? String {
                syntaxStack = [single]
            } else {
                syntaxStack = []
            }

            // Check for link first
            if let destination = attrs[.linkDestination] as? String {
                let wrapped = wrapWithSyntaxStack(text, stack: syntaxStack)
                result += "[\(wrapped)](\(destination))"
                return
            }

            // Apply inline syntax wrapping
            result += wrapWithSyntaxStack(text, stack: syntaxStack)
        }

        return result
    }

    private static func wrapWithSyntaxStack(_ text: String, stack: [String]) -> String {
        guard !stack.isEmpty else { return text }
        // Wrap from outermost to innermost: iterate in reverse (innermost first wraps closest)
        var wrapped = text
        for syntax in stack.reversed() {
            wrapped = "\(syntax)\(wrapped)\(syntax)"
        }
        return wrapped
    }
}
