import Testing
import Foundation
import AppKit
@testable import MarkDownApp

@Suite("Source Position Tests")
struct SourcePositionTests {

    let renderer = MarkupRenderer(stylesheet: .default)

    @Test("Heading has source position")
    func testHeadingSourcePosition() {
        let blocks = renderer.render(source: "# Hello")
        #expect(blocks.count == 1)
        let pos = blocks[0].sourcePosition
        #expect(pos != nil)
        #expect(pos?.startLine == 1)
        #expect(pos?.startColumn == 1)
    }

    @Test("Multiple blocks have distinct source positions")
    func testMultipleBlockPositions() {
        let source = """
        # Title

        Some text
        """
        let blocks = renderer.render(source: source)
        #expect(blocks.count == 2)
        #expect(blocks[0].sourcePosition != nil)
        #expect(blocks[1].sourcePosition != nil)
        #expect(blocks[0].sourcePosition!.startLine == 1)
        #expect(blocks[1].sourcePosition!.startLine == 3)
    }

    @Test("Code block has source position")
    func testCodeBlockSourcePosition() {
        let source = """
        ```swift
        let x = 1
        ```
        """
        let blocks = renderer.render(source: source)
        #expect(blocks.count == 1)
        #expect(blocks[0].sourcePosition != nil)
        #expect(blocks[0].sourcePosition!.startLine == 1)
    }

    @Test("List items have source positions")
    func testListItemSourcePositions() {
        let source = """
        - Item A
        - Item B
        """
        let blocks = renderer.render(source: source)
        #expect(blocks.count == 1)
        if case .children(let items) = blocks[0].content {
            #expect(items.count == 2)
            #expect(items[0].sourcePosition != nil)
            #expect(items[1].sourcePosition != nil)
            #expect(items[0].sourcePosition!.startLine == 1)
            #expect(items[1].sourcePosition!.startLine == 2)
        }
    }
}

@Suite("AttributedStringBuilder Tests")
struct AttributedStringBuilderTests {

    @Test("Builds plain text run")
    func testPlainTextRun() {
        let runs = [StyledRun(text: "Hello", elementType: .text, style: .empty)]
        let attrStr = AttributedStringBuilder.build(from: runs)
        #expect(attrStr.string == "Hello")
    }

    @Test("Builds multiple runs preserving text")
    func testMultipleRuns() {
        let runs = [
            StyledRun(text: "Hello ", elementType: .text, style: .empty),
            StyledRun(text: "bold", elementType: .strong, style: ElementStyle(fontWeight: .bold), syntaxStack: ["**"]),
            StyledRun(text: " world", elementType: .text, style: .empty),
        ]
        let attrStr = AttributedStringBuilder.build(from: runs)
        #expect(attrStr.string == "Hello bold world")
    }

    @Test("Sets markdownSyntax attribute for strong")
    func testStrongSyntaxAttribute() {
        let runs = [StyledRun(text: "bold", elementType: .strong, style: ElementStyle(fontWeight: .bold), syntaxStack: ["**"])]
        let attrStr = AttributedStringBuilder.build(from: runs)
        var foundSyntax: [String]?
        attrStr.enumerateAttribute(.markdownSyntax, in: NSRange(location: 0, length: attrStr.length)) { value, _, _ in
            foundSyntax = value as? [String]
        }
        #expect(foundSyntax == ["**"])
    }

    @Test("Sets markdownSyntax attribute for emphasis")
    func testEmphasisSyntaxAttribute() {
        let runs = [StyledRun(text: "italic", elementType: .emphasis, style: ElementStyle(isItalic: true), syntaxStack: ["*"])]
        let attrStr = AttributedStringBuilder.build(from: runs)
        var foundSyntax: [String]?
        attrStr.enumerateAttribute(.markdownSyntax, in: NSRange(location: 0, length: attrStr.length)) { value, _, _ in
            foundSyntax = value as? [String]
        }
        #expect(foundSyntax == ["*"])
    }

    @Test("Sets markdownSyntax attribute for inline code")
    func testInlineCodeSyntaxAttribute() {
        let runs = [StyledRun(text: "code", elementType: .inlineCode, style: ElementStyle(isMonospaced: true), syntaxStack: ["`"])]
        let attrStr = AttributedStringBuilder.build(from: runs)
        var foundSyntax: [String]?
        attrStr.enumerateAttribute(.markdownSyntax, in: NSRange(location: 0, length: attrStr.length)) { value, _, _ in
            foundSyntax = value as? [String]
        }
        #expect(foundSyntax == ["`"])
    }

    @Test("Sets linkDestination attribute for links")
    func testLinkDestinationAttribute() {
        let runs = [StyledRun(text: "Apple", elementType: .link, style: .empty, destination: "https://apple.com")]
        let attrStr = AttributedStringBuilder.build(from: runs)
        var foundDest: String?
        attrStr.enumerateAttribute(.linkDestination, in: NSRange(location: 0, length: attrStr.length)) { value, _, _ in
            foundDest = value as? String
        }
        #expect(foundDest == "https://apple.com")
    }

    @Test("Builds code block attributed string")
    func testCodeBlockBuilder() {
        let style = ElementStyle(fontSize: 13, isMonospaced: true)
        let attrStr = AttributedStringBuilder.buildCodeBlock(text: "let x = 1", style: style)
        #expect(attrStr.string == "let x = 1")
    }

    @Test("letterSpacing sets kern attribute")
    func testLetterSpacingKern() {
        let style = ElementStyle(letterSpacing: 2.5)
        let runs = [StyledRun(text: "spaced", elementType: .text, style: style)]
        let attrStr = AttributedStringBuilder.build(from: runs)
        var foundKern: CGFloat?
        attrStr.enumerateAttribute(.kern, in: NSRange(location: 0, length: attrStr.length)) { value, _, _ in
            foundKern = value as? CGFloat
        }
        #expect(foundKern == 2.5)
    }

    @Test("letterSpacing sets kern on code blocks")
    func testCodeBlockLetterSpacingKern() {
        let style = ElementStyle(fontSize: 13, letterSpacing: 1.5, isMonospaced: true)
        let attrStr = AttributedStringBuilder.buildCodeBlock(text: "code", style: style)
        var foundKern: CGFloat?
        attrStr.enumerateAttribute(.kern, in: NSRange(location: 0, length: attrStr.length)) { value, _, _ in
            foundKern = value as? CGFloat
        }
        #expect(foundKern == 1.5)
    }
}

@Suite("MarkdownReconstructor Tests")
struct MarkdownReconstructorTests {

    @Test("Reconstructs plain paragraph")
    func testPlainParagraph() {
        let attrStr = NSAttributedString(string: "Hello world", attributes: [
            .markdownElementType: MarkupElementType.text.rawValue
        ])
        let md = MarkdownReconstructor.reconstruct(attrStr, elementType: .paragraph)
        #expect(md == "Hello world")
    }

    @Test("Reconstructs heading 1")
    func testHeading1() {
        let attrStr = NSAttributedString(string: "Title", attributes: [
            .markdownElementType: MarkupElementType.text.rawValue
        ])
        let md = MarkdownReconstructor.reconstruct(attrStr, elementType: .heading1)
        #expect(md == "# Title")
    }

    @Test("Reconstructs heading 2")
    func testHeading2() {
        let attrStr = NSAttributedString(string: "Subtitle", attributes: [
            .markdownElementType: MarkupElementType.text.rawValue
        ])
        let md = MarkdownReconstructor.reconstruct(attrStr, elementType: .heading2)
        #expect(md == "## Subtitle")
    }

    @Test("Reconstructs bold text")
    func testBoldText() {
        let result = NSMutableAttributedString()
        result.append(NSAttributedString(string: "Hello ", attributes: [
            .markdownElementType: MarkupElementType.text.rawValue
        ]))
        result.append(NSAttributedString(string: "bold", attributes: [
            .markdownElementType: MarkupElementType.strong.rawValue,
            .markdownSyntax: ["**"] as [String],
        ]))
        result.append(NSAttributedString(string: " world", attributes: [
            .markdownElementType: MarkupElementType.text.rawValue
        ]))
        let md = MarkdownReconstructor.reconstruct(result, elementType: .paragraph)
        #expect(md == "Hello **bold** world")
    }

    @Test("Reconstructs italic text")
    func testItalicText() {
        let result = NSMutableAttributedString()
        result.append(NSAttributedString(string: "some ", attributes: [:]))
        result.append(NSAttributedString(string: "emphasis", attributes: [
            .markdownSyntax: ["*"] as [String],
        ]))
        let md = MarkdownReconstructor.reconstruct(result, elementType: .paragraph)
        #expect(md == "some *emphasis*")
    }

    @Test("Reconstructs inline code")
    func testInlineCode() {
        let result = NSMutableAttributedString()
        result.append(NSAttributedString(string: "Use ", attributes: [:]))
        result.append(NSAttributedString(string: "print()", attributes: [
            .markdownSyntax: ["`"] as [String],
        ]))
        result.append(NSAttributedString(string: " here", attributes: [:]))
        let md = MarkdownReconstructor.reconstruct(result, elementType: .paragraph)
        #expect(md == "Use `print()` here")
    }

    @Test("Reconstructs link")
    func testLink() {
        let attrStr = NSAttributedString(string: "Apple", attributes: [
            .linkDestination: "https://apple.com",
            .markdownElementType: MarkupElementType.link.rawValue,
        ])
        let md = MarkdownReconstructor.reconstruct(attrStr, elementType: .paragraph)
        #expect(md == "[Apple](https://apple.com)")
    }

    @Test("Reconstructs code block with fences")
    func testCodeBlock() {
        let attrStr = NSAttributedString(string: "let x = 42\n", attributes: [
            .markdownElementType: MarkupElementType.codeBlock.rawValue
        ])
        let md = MarkdownReconstructor.reconstruct(attrStr, elementType: .codeBlock, language: "swift")
        #expect(md == "```swift\nlet x = 42\n```")
    }

    @Test("Reconstructs code block without language")
    func testCodeBlockNoLanguage() {
        let attrStr = NSAttributedString(string: "echo hello\n", attributes: [:])
        let md = MarkdownReconstructor.reconstruct(attrStr, elementType: .codeBlock)
        #expect(md == "```\necho hello\n```")
    }

    @Test("Reconstructs strikethrough text")
    func testStrikethrough() {
        let result = NSMutableAttributedString()
        result.append(NSAttributedString(string: "removed", attributes: [
            .markdownSyntax: ["~~"] as [String],
        ]))
        let md = MarkdownReconstructor.reconstruct(result, elementType: .paragraph)
        #expect(md == "~~removed~~")
    }

    @Test("Reconstructs legacy single-string markdownSyntax for backward compat")
    func testLegacySingleStringSyntax() {
        let result = NSMutableAttributedString()
        result.append(NSAttributedString(string: "bold", attributes: [
            .markdownSyntax: "**",
        ]))
        let md = MarkdownReconstructor.reconstruct(result, elementType: .paragraph)
        #expect(md == "**bold**")
    }
}

@Suite("Round-Trip Tests")
struct RoundTripTests {

    let renderer = MarkupRenderer(stylesheet: .default)

    @Test("Paragraph round-trips through AttributedString and Reconstructor")
    func testParagraphRoundTrip() {
        let source = "This is **bold** and *italic* text."
        let blocks = renderer.render(source: source)
        #expect(blocks.count == 1)

        if case .inline(let runs) = blocks[0].content {
            let attrStr = AttributedStringBuilder.build(from: runs)
            let reconstructed = MarkdownReconstructor.reconstruct(attrStr, elementType: .paragraph)
            #expect(reconstructed == source)
        } else {
            Issue.record("Expected inline content")
        }
    }

    @Test("Heading round-trips through AttributedString and Reconstructor")
    func testHeadingRoundTrip() {
        let source = "# Hello World"
        let blocks = renderer.render(source: source)
        #expect(blocks.count == 1)

        if case .inline(let runs) = blocks[0].content {
            let attrStr = AttributedStringBuilder.build(from: runs)
            let reconstructed = MarkdownReconstructor.reconstruct(attrStr, elementType: .heading1)
            #expect(reconstructed == source)
        } else {
            Issue.record("Expected inline content")
        }
    }

    @Test("Inline code round-trips")
    func testInlineCodeRoundTrip() {
        let source = "Use `print()` here"
        let blocks = renderer.render(source: source)

        if case .inline(let runs) = blocks[0].content {
            let attrStr = AttributedStringBuilder.build(from: runs)
            let reconstructed = MarkdownReconstructor.reconstruct(attrStr, elementType: .paragraph)
            #expect(reconstructed == source)
        } else {
            Issue.record("Expected inline content")
        }
    }

    @Test("Link round-trips")
    func testLinkRoundTrip() {
        let source = "Visit [Apple](https://apple.com)"
        let blocks = renderer.render(source: source)

        if case .inline(let runs) = blocks[0].content {
            let attrStr = AttributedStringBuilder.build(from: runs)
            let reconstructed = MarkdownReconstructor.reconstruct(attrStr, elementType: .paragraph)
            #expect(reconstructed == source)
        } else {
            Issue.record("Expected inline content")
        }
    }

    @Test("Bold-italic round-trips")
    func testBoldItalicRoundTrip() {
        let source = "***bold italic***"
        let blocks = renderer.render(source: source)
        #expect(blocks.count == 1)

        if case .inline(let runs) = blocks[0].content {
            // Verify the syntax stack captures nesting
            #expect(runs.count >= 1)
            let attrStr = AttributedStringBuilder.build(from: runs)
            let reconstructed = MarkdownReconstructor.reconstruct(attrStr, elementType: .paragraph)
            // The reconstructor should produce valid markdown that re-parses equivalently
            // swift-markdown may parse ***x*** as emphasis wrapping strong or vice versa
            #expect(reconstructed.contains("bold italic"))
            // Verify it has both bold and italic markers
            #expect(reconstructed.contains("**"))
            #expect(reconstructed.contains("*"))
        } else {
            Issue.record("Expected inline content")
        }
    }

    @Test("Bold link round-trips")
    func testBoldLinkRoundTrip() {
        let source = "**[link](https://example.com)**"
        let blocks = renderer.render(source: source)
        #expect(blocks.count == 1)

        if case .inline(let runs) = blocks[0].content {
            let attrStr = AttributedStringBuilder.build(from: runs)
            let reconstructed = MarkdownReconstructor.reconstruct(attrStr, elementType: .paragraph)
            // Should contain both link syntax and bold syntax
            #expect(reconstructed.contains("link"))
            #expect(reconstructed.contains("(https://example.com)"))
            #expect(reconstructed.contains("**"))
            #expect(reconstructed.contains("["))
        } else {
            Issue.record("Expected inline content")
        }
    }
}

@Suite("resolvedNSFont Tests")
struct ResolvedNSFontTests {

    @Test("Default style produces system font")
    func testDefaultFont() {
        let style = ElementStyle(fontSize: 14)
        let font = style.resolvedNSFont
        #expect(font.pointSize == 14)
    }

    @Test("Monospaced style produces monospaced font")
    func testMonospacedFont() {
        let style = ElementStyle(fontSize: 13, isMonospaced: true)
        let font = style.resolvedNSFont
        #expect(font.pointSize == 13)
        // Check it's monospaced by verifying the font descriptor
        let traits = font.fontDescriptor.symbolicTraits
        #expect(traits.contains(.monoSpace))
    }

    @Test("Bold style produces bold font")
    func testBoldFont() {
        let style = ElementStyle(fontSize: 16, fontWeight: .bold)
        let font = style.resolvedNSFont
        #expect(font.pointSize == 16)
    }
}

@Suite("ElementStyle Validation Tests")
struct ElementStyleValidationTests {

    @Test("Validates font size range")
    func testFontSizeValidation() {
        let style = ElementStyle(fontSize: 500)
        let validated = style.validated()
        #expect(validated.fontSize == 200)

        let small = ElementStyle(fontSize: -5)
        let validatedSmall = small.validated()
        #expect(validatedSmall.fontSize == 1)
    }

    @Test("Validates padding range")
    func testPaddingValidation() {
        let style = ElementStyle(paddingTop: 300, paddingBottom: -10)
        let validated = style.validated()
        #expect(validated.paddingTop == 200)
        #expect(validated.paddingBottom == 0)
    }

    @Test("Validates letter spacing range")
    func testLetterSpacingValidation() {
        let style = ElementStyle(letterSpacing: 100)
        let validated = style.validated()
        #expect(validated.letterSpacing == 50)

        let negative = ElementStyle(letterSpacing: -20)
        let validatedNeg = negative.validated()
        #expect(validatedNeg.letterSpacing == -10)
    }

    @Test("Nil values pass through unchanged")
    func testNilPassthrough() {
        let style = ElementStyle()
        let validated = style.validated()
        #expect(validated.fontSize == nil)
        #expect(validated.paddingTop == nil)
        #expect(validated.letterSpacing == nil)
    }
}
