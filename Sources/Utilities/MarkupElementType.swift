import Foundation

/// Maps swift-markdown AST node types to stylesheet keys
enum MarkupElementType: String, Codable, CaseIterable, Hashable, Identifiable {
    case heading1
    case heading2
    case heading3
    case heading4
    case heading5
    case heading6
    case paragraph
    case blockQuote
    case codeBlock
    case orderedList
    case unorderedList
    case listItem
    case thematicBreak
    case table
    case tableHeader
    case tableRow
    case tableCell
    case text
    case emphasis
    case strong
    case strikethrough
    case inlineCode
    case link
    case image

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .heading1: return "Heading 1"
        case .heading2: return "Heading 2"
        case .heading3: return "Heading 3"
        case .heading4: return "Heading 4"
        case .heading5: return "Heading 5"
        case .heading6: return "Heading 6"
        case .paragraph: return "Paragraph"
        case .blockQuote: return "Block Quote"
        case .codeBlock: return "Code Block"
        case .orderedList: return "Ordered List"
        case .unorderedList: return "Unordered List"
        case .listItem: return "List Item"
        case .thematicBreak: return "Thematic Break"
        case .table: return "Table"
        case .tableHeader: return "Table Header"
        case .tableRow: return "Table Row"
        case .tableCell: return "Table Cell"
        case .text: return "Text"
        case .emphasis: return "Emphasis"
        case .strong: return "Strong"
        case .strikethrough: return "Strikethrough"
        case .inlineCode: return "Inline Code"
        case .link: return "Link"
        case .image: return "Image"
        }
    }

    var isBlock: Bool {
        switch self {
        case .heading1, .heading2, .heading3, .heading4, .heading5, .heading6,
             .paragraph, .blockQuote, .codeBlock, .orderedList, .unorderedList,
             .listItem, .thematicBreak, .table, .tableHeader, .tableRow, .tableCell:
            return true
        case .text, .emphasis, .strong, .strikethrough, .inlineCode, .link, .image:
            return false
        }
    }

    var isInline: Bool { !isBlock }

    var isHeading: Bool {
        switch self {
        case .heading1, .heading2, .heading3, .heading4, .heading5, .heading6:
            return true
        default:
            return false
        }
    }
}
