import Foundation
import Markdown

/// Walks a swift-markdown AST and produces [StyledBlock] for rendering
struct MarkupRenderer {
    let stylesheet: StyleSheet
    /// Generation counter baked into block IDs so SwiftUI creates fresh views after a full rerender
    var generation: Int = 0

    func render(source: String) -> [StyledBlock] {
        let document = Document(parsing: source)
        let inlineRenderer = InlineRenderer(stylesheet: stylesheet)
        return renderBlock(document, inlineRenderer: inlineRenderer, insideListItem: false)
    }

    func render(document: Document) -> [StyledBlock] {
        let inlineRenderer = InlineRenderer(stylesheet: stylesheet)
        return renderBlock(document, inlineRenderer: inlineRenderer, insideListItem: false)
    }

    private func renderBlock(_ node: Markup, inlineRenderer: InlineRenderer, insideListItem: Bool) -> [StyledBlock] {
        var blocks: [StyledBlock] = []

        for child in node.children {
            if let block = renderSingleBlock(child, inlineRenderer: inlineRenderer, insideListItem: insideListItem) {
                blocks.append(block)
            }
        }

        return blocks
    }

    private func sourcePosition(from node: Markup) -> SourcePosition? {
        guard let range = node.range else { return nil }
        return SourcePosition(
            startLine: range.lowerBound.line,
            startColumn: range.lowerBound.column,
            endLine: range.upperBound.line,
            endColumn: range.upperBound.column
        )
    }

    private func renderSingleBlock(_ node: Markup, inlineRenderer: InlineRenderer, insideListItem: Bool) -> StyledBlock? {
        let pos = sourcePosition(from: node)

        switch node {
        case let heading as Markdown.Heading:
            let elementType = headingType(level: heading.level)
            let style = stylesheet.resolvedStyle(for: elementType)
            let runs = inlineRenderer.renderInlines(heading.children, parentStyle: style)
            return StyledBlock(elementType: elementType, style: style, content: .inline(runs), sourcePosition: pos, generation: generation)

        case let paragraph as Markdown.Paragraph:
            // Check if paragraph contains a single image
            if paragraph.childCount == 1 {
                for child in paragraph.children {
                    if let img = child as? Markdown.Image {
                        let style = stylesheet.resolvedStyle(for: .image)
                        let alt = img.children.compactMap { ($0 as? Markdown.Text)?.string }.joined()
                        return StyledBlock(
                            elementType: .image, style: style,
                            content: .image(source: img.source ?? "", alt: alt),
                            sourcePosition: pos
                        )
                    }
                }
            }
            var style = stylesheet.resolvedStyle(for: .paragraph)
            if insideListItem {
                // Use list item's lineSpacing so paragraph Line Gap changes don't cascade into lists
                style.lineSpacing = stylesheet.resolvedStyle(for: .listItem).lineSpacing
            }
            let runs = inlineRenderer.renderInlines(paragraph.children, parentStyle: style)
            return StyledBlock(elementType: .paragraph, style: style, content: .inline(runs), sourcePosition: pos, generation: generation)

        case let blockQuote as Markdown.BlockQuote:
            let style = stylesheet.resolvedStyle(for: .blockQuote)
            let children = renderBlock(blockQuote, inlineRenderer: inlineRenderer, insideListItem: false)
            return StyledBlock(elementType: .blockQuote, style: style, content: .children(children), sourcePosition: pos, generation: generation)

        case let codeBlock as Markdown.CodeBlock:
            let style = stylesheet.resolvedStyle(for: .codeBlock)
            return StyledBlock(
                elementType: .codeBlock, style: style,
                content: .code(language: codeBlock.language, text: codeBlock.code.hasSuffix("\n") ? String(codeBlock.code.dropLast()) : codeBlock.code),
                sourcePosition: pos
            )

        case let orderedList as Markdown.OrderedList:
            let style = stylesheet.resolvedStyle(for: .orderedList)
            var children: [StyledBlock] = []
            for (index, item) in orderedList.children.enumerated() {
                if let listItem = item as? Markdown.ListItem {
                    let itemStyle = stylesheet.resolvedStyle(for: .listItem)
                    let itemChildren = renderBlock(listItem, inlineRenderer: inlineRenderer, insideListItem: true)
                    let marker: String
                    if let checkbox = listItem.checkbox {
                        marker = checkbox == .checked ? "☑" : "☐"
                    } else {
                        marker = "\(Int(orderedList.startIndex) + index)."
                    }
                    let itemPos = sourcePosition(from: listItem)
                    children.append(StyledBlock(
                        elementType: .listItem, style: itemStyle,
                        content: .listItem(marker: marker, children: itemChildren),
                        sourcePosition: itemPos, generation: generation
                    ))
                }
            }
            return StyledBlock(elementType: .orderedList, style: style, content: .children(children), sourcePosition: pos, generation: generation)

        case let unorderedList as Markdown.UnorderedList:
            let style = stylesheet.resolvedStyle(for: .unorderedList)
            var children: [StyledBlock] = []
            for item in unorderedList.children {
                if let listItem = item as? Markdown.ListItem {
                    let itemStyle = stylesheet.resolvedStyle(for: .listItem)
                    let itemChildren = renderBlock(listItem, inlineRenderer: inlineRenderer, insideListItem: true)
                    let marker: String
                    if let checkbox = listItem.checkbox {
                        marker = checkbox == .checked ? "☑" : "☐"
                    } else {
                        marker = "\u{2022}"
                    }
                    let itemPos = sourcePosition(from: listItem)
                    children.append(StyledBlock(
                        elementType: .listItem, style: itemStyle,
                        content: .listItem(marker: marker, children: itemChildren),
                        sourcePosition: itemPos, generation: generation
                    ))
                }
            }
            return StyledBlock(elementType: .unorderedList, style: style, content: .children(children), sourcePosition: pos, generation: generation)

        case is Markdown.ThematicBreak:
            let style = stylesheet.resolvedStyle(for: .thematicBreak)
            return StyledBlock(elementType: .thematicBreak, style: style, content: .thematicBreak, sourcePosition: pos, generation: generation)

        case let htmlBlock as Markdown.HTMLBlock:
            let style = stylesheet.resolvedStyle(for: .codeBlock)
            return StyledBlock(
                elementType: .codeBlock, style: style,
                content: .code(language: "html", text: htmlBlock.rawHTML.hasSuffix("\n") ? String(htmlBlock.rawHTML.dropLast()) : htmlBlock.rawHTML),
                sourcePosition: pos
            )

        case let table as Markdown.Table:
            return renderTable(table, inlineRenderer: inlineRenderer)

        default:
            // Attempt to render as paragraph with inline content
            let style = stylesheet.resolvedStyle(for: .paragraph)
            let runs = inlineRenderer.renderInlines(node.children, parentStyle: style)
            if !runs.isEmpty {
                return StyledBlock(elementType: .paragraph, style: style, content: .inline(runs), sourcePosition: pos, generation: generation)
            }
            return nil
        }
    }

    private func renderTable(_ table: Markdown.Table, inlineRenderer: InlineRenderer) -> StyledBlock {
        let tableStyle = stylesheet.resolvedStyle(for: .table)
        let pos = sourcePosition(from: table)

        // Header
        let headerStyle = stylesheet.resolvedStyle(for: .tableHeader)
        let headerCells: [StyledTableCell] = table.head.cells.enumerated().map { colIndex, cell in
            let runs = inlineRenderer.renderInlines(cell.children, parentStyle: headerStyle)
            let cellPos = sourcePosition(from: cell)
            return StyledTableCell(id: "header-\(colIndex)", runs: runs, style: headerStyle, isHeader: true, sourcePosition: cellPos)
        }

        // Rows
        let cellStyle = stylesheet.resolvedStyle(for: .tableCell)
        var rows: [[StyledTableCell]] = []
        for (rowIndex, row) in table.body.rows.enumerated() {
            let cells: [StyledTableCell] = row.cells.enumerated().map { colIndex, cell in
                let runs = inlineRenderer.renderInlines(cell.children, parentStyle: cellStyle)
                let cellPos = sourcePosition(from: cell)
                return StyledTableCell(id: "row-\(rowIndex)-\(colIndex)", runs: runs, style: cellStyle, isHeader: false, sourcePosition: cellPos)
            }
            rows.append(cells)
        }

        return StyledBlock(
            elementType: .table, style: tableStyle,
            content: .table(header: headerCells, rows: rows),
            sourcePosition: pos
        )
    }

    private func headingType(level: Int) -> MarkupElementType {
        switch level {
        case 1: return .heading1
        case 2: return .heading2
        case 3: return .heading3
        case 4: return .heading4
        case 5: return .heading5
        case 6: return .heading6
        default: return .heading1
        }
    }
}
