import Foundation

/// A named collection of element styles that can be saved and shared as JSON
struct StyleSheet: Codable, Identifiable, Equatable, Hashable {
    var id: UUID
    var name: String
    var author: String?
    var description: String?
    var createdAt: Date
    var modifiedAt: Date
    var styles: [MarkupElementType: ElementStyle]
    var pageBackgroundColor: CodableColor?

    init(
        id: UUID = UUID(),
        name: String = "Untitled",
        author: String? = nil,
        description: String? = nil,
        createdAt: Date = Date(),
        modifiedAt: Date = Date(),
        styles: [MarkupElementType: ElementStyle] = [:],
        pageBackgroundColor: CodableColor? = nil
    ) {
        self.id = id
        self.name = name
        self.author = author
        self.description = description
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.styles = styles
        self.pageBackgroundColor = pageBackgroundColor
    }

    /// Resolve the effective style for an element type by merging defaults with custom overrides
    func resolvedStyle(for elementType: MarkupElementType) -> ElementStyle {
        let defaultStyle = DefaultStyles.style(for: elementType)
        guard let customStyle = styles[elementType] else {
            return defaultStyle
        }
        return defaultStyle.merging(with: customStyle)
    }

    /// Update a style for a specific element type
    mutating func setStyle(_ style: ElementStyle, for elementType: MarkupElementType) {
        styles[elementType] = style
        modifiedAt = Date()
    }

    /// Remove custom style for element type, reverting to defaults
    mutating func removeStyle(for elementType: MarkupElementType) {
        styles.removeValue(forKey: elementType)
        modifiedAt = Date()
    }

    // MARK: - Hashable (hash by id only)

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    /// The default stylesheet with no custom overrides
    static let `default` = StyleSheet(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        name: "Default",
        description: "Built-in default styling",
        pageBackgroundColor: .white
    )

    /// Stock stylesheets that ship with the app
    static let stockStylesheets: [StyleSheet] = [.default, .darkMode]

    /// Dark mode stylesheet
    static let darkMode = StyleSheet(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
        name: "Dark Mode",
        description: "Light text on a dark background",
        styles: [
            .heading1: ElementStyle(
                fontSize: 32, fontWeight: .bold,
                foregroundColor: CodableColor(red: 0.95, green: 0.95, blue: 0.97)
            ),
            .heading2: ElementStyle(
                fontSize: 26, fontWeight: .bold,
                foregroundColor: CodableColor(red: 0.9, green: 0.9, blue: 0.95)
            ),
            .heading3: ElementStyle(
                fontSize: 22, fontWeight: .semibold,
                foregroundColor: CodableColor(red: 0.85, green: 0.85, blue: 0.92)
            ),
            .heading4: ElementStyle(
                fontSize: 18, fontWeight: .semibold,
                foregroundColor: CodableColor(red: 0.8, green: 0.8, blue: 0.88)
            ),
            .heading5: ElementStyle(
                fontSize: 16, fontWeight: .medium,
                foregroundColor: CodableColor(red: 0.78, green: 0.78, blue: 0.85)
            ),
            .heading6: ElementStyle(
                fontSize: 14, fontWeight: .medium,
                foregroundColor: CodableColor(red: 0.6, green: 0.6, blue: 0.68)
            ),
            .paragraph: ElementStyle(
                fontSize: 14,
                foregroundColor: CodableColor(red: 0.82, green: 0.82, blue: 0.85)
            ),
            .blockQuote: ElementStyle(
                fontSize: 14, isItalic: true,
                foregroundColor: CodableColor(red: 0.65, green: 0.65, blue: 0.72),
                backgroundColor: CodableColor(red: 0.18, green: 0.18, blue: 0.22),
                borderColor: CodableColor(red: 0.4, green: 0.4, blue: 0.5),
                borderWidth: 3
            ),
            .codeBlock: ElementStyle(
                fontSize: 13,
                foregroundColor: CodableColor(red: 0.78, green: 0.85, blue: 0.65),
                backgroundColor: CodableColor(red: 0.12, green: 0.12, blue: 0.15),
                cornerRadius: 6,
                isMonospaced: true
            ),
            .orderedList: ElementStyle(
                foregroundColor: CodableColor(red: 0.82, green: 0.82, blue: 0.85)
            ),
            .unorderedList: ElementStyle(
                foregroundColor: CodableColor(red: 0.82, green: 0.82, blue: 0.85)
            ),
            .listItem: ElementStyle(
                foregroundColor: CodableColor(red: 0.82, green: 0.82, blue: 0.85)
            ),
            .thematicBreak: ElementStyle(
                foregroundColor: CodableColor(red: 0.35, green: 0.35, blue: 0.4)
            ),
            .table: ElementStyle(
                foregroundColor: CodableColor(red: 0.82, green: 0.82, blue: 0.85),
                borderColor: CodableColor(red: 0.3, green: 0.3, blue: 0.35)
            ),
            .tableHeader: ElementStyle(
                fontWeight: .semibold,
                foregroundColor: CodableColor(red: 0.9, green: 0.9, blue: 0.95),
                backgroundColor: CodableColor(red: 0.22, green: 0.22, blue: 0.26)
            ),
            .tableRow: ElementStyle(
                foregroundColor: CodableColor(red: 0.82, green: 0.82, blue: 0.85)
            ),
            .tableCell: ElementStyle(
                foregroundColor: CodableColor(red: 0.82, green: 0.82, blue: 0.85)
            ),
            .inlineCode: ElementStyle(
                fontSize: 13,
                foregroundColor: CodableColor(red: 0.9, green: 0.55, blue: 0.6),
                backgroundColor: CodableColor(red: 0.18, green: 0.18, blue: 0.22),
                cornerRadius: 3,
                isMonospaced: true
            ),
            .link: ElementStyle(
                foregroundColor: CodableColor(red: 0.45, green: 0.65, blue: 1.0)
            ),
            .strikethrough: ElementStyle(
                foregroundColor: CodableColor(red: 0.5, green: 0.5, blue: 0.55)
            ),
        ],
        pageBackgroundColor: CodableColor(red: 0.15, green: 0.15, blue: 0.18)
    )
}
