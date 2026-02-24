import Testing
import Foundation
@testable import MarkDownApp

@Suite("MarkupRenderer Tests")
struct MarkupRendererTests {

    let renderer = MarkupRenderer(stylesheet: .default)

    @Test("Renders heading correctly")
    func testHeading() {
        let blocks = renderer.render(source: "# Hello World")
        #expect(blocks.count == 1)
        #expect(blocks[0].elementType == .heading1)

        if case .inline(let runs) = blocks[0].content {
            let text = runs.map(\.text).joined()
            #expect(text == "Hello World")
        } else {
            Issue.record("Expected inline content for heading")
        }
    }

    @Test("Renders multiple heading levels")
    func testHeadingLevels() {
        let source = """
        # H1
        ## H2
        ### H3
        """
        let blocks = renderer.render(source: source)
        #expect(blocks.count == 3)
        #expect(blocks[0].elementType == .heading1)
        #expect(blocks[1].elementType == .heading2)
        #expect(blocks[2].elementType == .heading3)
    }

    @Test("Renders paragraph with inline formatting")
    func testParagraphWithFormatting() {
        let blocks = renderer.render(source: "This is **bold** and *italic* text.")
        #expect(blocks.count == 1)
        #expect(blocks[0].elementType == .paragraph)

        if case .inline(let runs) = blocks[0].content {
            #expect(runs.count >= 3) // at least: "This is ", "bold", " and ", "italic", " text."
            let boldRun = runs.first { $0.elementType == .strong }
            #expect(boldRun?.text == "bold")
            let italicRun = runs.first { $0.elementType == .emphasis }
            #expect(italicRun?.text == "italic")
        } else {
            Issue.record("Expected inline content")
        }
    }

    @Test("Renders code block")
    func testCodeBlock() {
        let source = """
        ```swift
        let x = 42
        ```
        """
        let blocks = renderer.render(source: source)
        #expect(blocks.count == 1)
        #expect(blocks[0].elementType == .codeBlock)

        if case .code(let language, let text) = blocks[0].content {
            #expect(language == "swift")
            #expect(text.contains("let x = 42"))
        } else {
            Issue.record("Expected code content")
        }
    }

    @Test("Renders block quote")
    func testBlockQuote() {
        let blocks = renderer.render(source: "> A wise quote")
        #expect(blocks.count == 1)
        #expect(blocks[0].elementType == .blockQuote)

        if case .children(let children) = blocks[0].content {
            #expect(children.count == 1)
            #expect(children[0].elementType == .paragraph)
        } else {
            Issue.record("Expected children content")
        }
    }

    @Test("Renders unordered list")
    func testUnorderedList() {
        let source = """
        - Item A
        - Item B
        - Item C
        """
        let blocks = renderer.render(source: source)
        #expect(blocks.count == 1)
        #expect(blocks[0].elementType == .unorderedList)

        if case .children(let items) = blocks[0].content {
            #expect(items.count == 3)
            #expect(items[0].elementType == .listItem)
        } else {
            Issue.record("Expected children content")
        }
    }

    @Test("Renders ordered list")
    func testOrderedList() {
        let source = """
        1. First
        2. Second
        """
        let blocks = renderer.render(source: source)
        #expect(blocks.count == 1)
        #expect(blocks[0].elementType == .orderedList)

        if case .children(let items) = blocks[0].content {
            #expect(items.count == 2)
            if case .listItem(let marker, _) = items[0].content {
                #expect(marker == "1.")
            }
        } else {
            Issue.record("Expected children content")
        }
    }

    @Test("Renders thematic break")
    func testThematicBreak() {
        let blocks = renderer.render(source: "---")
        #expect(blocks.count == 1)
        #expect(blocks[0].elementType == .thematicBreak)
    }

    @Test("Renders inline code")
    func testInlineCode() {
        let blocks = renderer.render(source: "Use `print()` here")
        #expect(blocks.count == 1)

        if case .inline(let runs) = blocks[0].content {
            let codeRun = runs.first { $0.elementType == .inlineCode }
            #expect(codeRun?.text == "print()")
        } else {
            Issue.record("Expected inline content")
        }
    }

    @Test("Renders link")
    func testLink() {
        let blocks = renderer.render(source: "Visit [Apple](https://apple.com)")
        #expect(blocks.count == 1)

        if case .inline(let runs) = blocks[0].content {
            let linkRun = runs.first { $0.elementType == .link }
            #expect(linkRun?.text == "Apple")
            #expect(linkRun?.destination == "https://apple.com")
        } else {
            Issue.record("Expected inline content")
        }
    }

    @Test("Renders sample table with content")
    func testSampleTableContent() {
        let source = """
        | Feature       | Status    | Notes          |
        |---------------|-----------|----------------|
        | Live Preview  | Complete  | Updates as you type |
        """
        let blocks = renderer.render(source: source)
        #expect(blocks.count == 1)
        if case .table(let header, let rows) = blocks[0].content {
            #expect(header[0].runs.first?.text == "Feature")
            #expect(header[1].runs.first?.text == "Status")
            #expect(header[2].runs.first?.text == "Notes")
            #expect(rows[0][0].runs.first?.text == "Live Preview")
            #expect(rows[0][1].runs.first?.text == "Complete")
            #expect(rows[0][2].runs.first?.text == "Updates as you type")
        } else {
            Issue.record("Expected table content")
        }
    }

    @Test("Renders table")
    func testTable() {
        let source = """
        | A | B |
        |---|---|
        | 1 | 2 |
        """
        let blocks = renderer.render(source: source)
        #expect(blocks.count == 1)
        #expect(blocks[0].elementType == .table)

        if case .table(let header, let rows) = blocks[0].content {
            #expect(header.count == 2)
            #expect(rows.count == 1)
            #expect(rows[0].count == 2)
            // Verify cells have text content
            #expect(!header[0].runs.isEmpty, "Header cell 0 has no runs")
            #expect(!header[1].runs.isEmpty, "Header cell 1 has no runs")
            #expect(header[0].runs.first?.text == "A")
            #expect(header[1].runs.first?.text == "B")
            #expect(rows[0][0].runs.first?.text == "1")
            #expect(rows[0][1].runs.first?.text == "2")
        } else {
            Issue.record("Expected table content")
        }
    }

    @Test("Renders image")
    func testImage() {
        let blocks = renderer.render(source: "![Mark Down](AppIcon.iconset/icon_256x256.png)")
        #expect(blocks.count == 1)
        #expect(blocks[0].elementType == .image)
        if case .image(let source, let alt) = blocks[0].content {
            #expect(source == "AppIcon.iconset/icon_256x256.png")
            #expect(alt == "Mark Down")
        } else {
            Issue.record("Expected image content, got \(blocks[0].content)")
        }
    }
}
