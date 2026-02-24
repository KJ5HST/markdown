import Foundation

/// Tracks where a block lives in the markdown source (1-indexed, from swift-markdown)
struct SourcePosition: Equatable {
    let startLine: Int
    let startColumn: Int
    let endLine: Int
    let endColumn: Int
}

/// Intermediate representation between AST and SwiftUI views
struct StyledBlock: Identifiable {
    /// Stable ID derived from source position so ForEach can diff across rerenders
    let id: String
    let elementType: MarkupElementType
    let style: ElementStyle
    let content: BlockContent
    let sourcePosition: SourcePosition?

    init(elementType: MarkupElementType, style: ElementStyle, content: BlockContent, sourcePosition: SourcePosition?, generation: Int = 0) {
        if let pos = sourcePosition {
            self.id = "\(elementType.rawValue)-\(pos.startLine)-\(pos.startColumn)-g\(generation)"
        } else {
            self.id = UUID().uuidString
        }
        self.elementType = elementType
        self.style = style
        self.content = content
        self.sourcePosition = sourcePosition
    }

    enum BlockContent {
        case inline([StyledRun])
        case children([StyledBlock])
        case code(language: String?, text: String)
        case thematicBreak
        case image(source: String, alt: String)
        case table(header: [StyledTableCell], rows: [[StyledTableCell]])
        case listItem(marker: String, children: [StyledBlock])
    }
}

/// A styled run of inline text
struct StyledRun: Identifiable {
    let id: String
    let text: String
    let elementType: MarkupElementType
    let style: ElementStyle
    let destination: String? // For links
    let syntaxStack: [String]

    init(text: String, elementType: MarkupElementType, style: ElementStyle, destination: String? = nil, id: String = UUID().uuidString, syntaxStack: [String] = []) {
        self.id = id
        self.text = text
        self.elementType = elementType
        self.style = style
        self.destination = destination
        self.syntaxStack = syntaxStack
    }
}

/// A styled table cell
struct StyledTableCell: Identifiable {
    let id: String
    let runs: [StyledRun]
    let style: ElementStyle
    let isHeader: Bool
    let sourcePosition: SourcePosition?

    init(id: String = UUID().uuidString, runs: [StyledRun], style: ElementStyle, isHeader: Bool, sourcePosition: SourcePosition? = nil) {
        self.id = id
        self.runs = runs
        self.style = style
        self.isHeader = isHeader
        self.sourcePosition = sourcePosition
    }
}
