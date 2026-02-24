import Foundation

/// Built-in default styles for each element type
enum DefaultStyles {
    static func style(for elementType: MarkupElementType) -> ElementStyle {
        switch elementType {
        case .heading1:
            return ElementStyle(
                fontSize: 32, fontWeight: .bold,
                foregroundColor: .black,
                paddingTop: 16, paddingBottom: 8, lineSpacing: 4
            )
        case .heading2:
            return ElementStyle(
                fontSize: 26, fontWeight: .bold,
                foregroundColor: .black,
                paddingTop: 14, paddingBottom: 6, lineSpacing: 4
            )
        case .heading3:
            return ElementStyle(
                fontSize: 22, fontWeight: .semibold,
                foregroundColor: .black,
                paddingTop: 12, paddingBottom: 4, lineSpacing: 3
            )
        case .heading4:
            return ElementStyle(
                fontSize: 18, fontWeight: .semibold,
                foregroundColor: .black,
                paddingTop: 10, paddingBottom: 4, lineSpacing: 2
            )
        case .heading5:
            return ElementStyle(
                fontSize: 16, fontWeight: .medium,
                foregroundColor: .black,
                paddingTop: 8, paddingBottom: 2, lineSpacing: 2
            )
        case .heading6:
            return ElementStyle(
                fontSize: 14, fontWeight: .medium,
                foregroundColor: CodableColor(red: 0.4, green: 0.4, blue: 0.4),
                paddingTop: 8, paddingBottom: 2, lineSpacing: 2
            )
        case .paragraph:
            return ElementStyle(
                fontSize: 14,
                foregroundColor: .black,
                paddingTop: 0, paddingBottom: 4,
                paddingLeading: 8,
                lineSpacing: 4
            )
        case .blockQuote:
            return ElementStyle(
                fontSize: 14, isItalic: true,
                foregroundColor: CodableColor(red: 0.3, green: 0.3, blue: 0.3),
                backgroundColor: CodableColor(red: 0.96, green: 0.96, blue: 0.96),
                paddingTop: 8, paddingBottom: 8,
                paddingLeading: 16, paddingTrailing: 8,
                lineSpacing: 3,
                borderColor: CodableColor(red: 0.75, green: 0.75, blue: 0.75),
                borderWidth: 3, cornerRadius: 2
            )
        case .codeBlock:
            return ElementStyle(
                fontSize: 13,
                foregroundColor: CodableColor(red: 0.2, green: 0.2, blue: 0.2),
                backgroundColor: CodableColor(red: 0.95, green: 0.95, blue: 0.95),
                paddingTop: 12, paddingBottom: 12,
                paddingLeading: 12, paddingTrailing: 12,
                lineSpacing: 3, cornerRadius: 6,
                isMonospaced: true
            )
        case .orderedList, .unorderedList:
            return ElementStyle(
                fontSize: 14,
                foregroundColor: .black,
                paddingTop: 4, paddingBottom: 4,
                paddingLeading: 8
            )
        case .listItem:
            return ElementStyle(
                fontSize: 14,
                foregroundColor: .black,
                paddingTop: 2, paddingBottom: 2
            )
        case .thematicBreak:
            return ElementStyle(
                foregroundColor: CodableColor(red: 0.8, green: 0.8, blue: 0.8),
                paddingTop: 12, paddingBottom: 12
            )
        case .table:
            return ElementStyle(
                fontSize: 13,
                foregroundColor: .black,
                paddingTop: 8, paddingBottom: 8,
                borderColor: CodableColor(red: 0.85, green: 0.85, blue: 0.85),
                borderWidth: 1
            )
        case .tableHeader:
            return ElementStyle(
                fontSize: 13, fontWeight: .semibold,
                foregroundColor: .black,
                backgroundColor: CodableColor(red: 0.95, green: 0.95, blue: 0.95),
                paddingTop: 6, paddingBottom: 6,
                paddingLeading: 8, paddingTrailing: 8
            )
        case .tableRow:
            return ElementStyle(
                fontSize: 13,
                foregroundColor: .black,
                paddingTop: 4, paddingBottom: 4,
                paddingLeading: 8, paddingTrailing: 8
            )
        case .tableCell:
            return ElementStyle(
                fontSize: 13,
                paddingTop: 4, paddingBottom: 4,
                paddingLeading: 8, paddingTrailing: 8
            )
        case .text:
            // Plain text inherits font/color from its parent block
            return ElementStyle()
        case .emphasis:
            // Only adds italic — font size/color inherited from parent block
            return ElementStyle(isItalic: true)
        case .strong:
            // Only adds bold — font size/color inherited from parent block
            return ElementStyle(fontWeight: .bold)
        case .strikethrough:
            // Only overrides color
            return ElementStyle(foregroundColor: .gray)
        case .inlineCode:
            return ElementStyle(
                fontSize: 13,
                foregroundColor: CodableColor(red: 0.8, green: 0.15, blue: 0.3),
                backgroundColor: CodableColor(red: 0.95, green: 0.95, blue: 0.95),
                paddingLeading: 4, paddingTrailing: 4,
                cornerRadius: 3,
                isMonospaced: true
            )
        case .link:
            // Only overrides color
            return ElementStyle(foregroundColor: .blue)
        case .image:
            return ElementStyle(
                paddingTop: 8, paddingBottom: 8,
                cornerRadius: 4
            )
        }
    }
}
