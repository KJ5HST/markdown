import Testing
import Foundation
@testable import MarkDownApp

@Suite("StyleSheet Tests")
struct StyleSheetTests {

    @Test("Encode and decode StyleSheet round-trip")
    func testRoundTrip() throws {
        var sheet = StyleSheet(name: "Test Sheet", author: "Tester", description: "A test stylesheet")
        sheet.setStyle(
            ElementStyle(fontSize: 24, fontWeight: .bold, foregroundColor: .blue),
            for: .heading1
        )
        sheet.setStyle(
            ElementStyle(fontSize: 14, isItalic: true, backgroundColor: .gray),
            for: .blockQuote
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let data = try encoder.encode(sheet)
        let decoded = try decoder.decode(StyleSheet.self, from: data)

        #expect(decoded.name == "Test Sheet")
        #expect(decoded.author == "Tester")
        #expect(decoded.styles.count == 2)
        #expect(decoded.styles[.heading1]?.fontSize == 24)
        #expect(decoded.styles[.heading1]?.fontWeight == .bold)
        #expect(decoded.styles[.blockQuote]?.isItalic == true)
    }

    @Test("Resolved style merges defaults with custom")
    func testResolvedStyle() {
        var sheet = StyleSheet.default
        // Heading1 default has fontSize 32, fontWeight .bold
        let defaultStyle = sheet.resolvedStyle(for: .heading1)
        #expect(defaultStyle.fontSize == 32)
        #expect(defaultStyle.fontWeight == .bold)

        // Override just the font size
        sheet.setStyle(ElementStyle(fontSize: 48), for: .heading1)
        let resolved = sheet.resolvedStyle(for: .heading1)
        #expect(resolved.fontSize == 48) // overridden
        #expect(resolved.fontWeight == .bold) // inherited from default
    }

    @Test("ElementStyle merging preserves non-nil values")
    func testMerging() {
        let base = ElementStyle(fontSize: 14, fontWeight: .regular, foregroundColor: .black)
        let overlay = ElementStyle(fontSize: 20, isItalic: true)
        let merged = base.merging(with: overlay)

        #expect(merged.fontSize == 20) // overridden
        #expect(merged.fontWeight == .regular) // kept from base
        #expect(merged.isItalic == true) // added from overlay
        #expect(merged.foregroundColor == .black) // kept from base
    }

    @Test("CodableColor encodes and decodes")
    func testCodableColor() throws {
        let color = CodableColor(red: 0.5, green: 0.25, blue: 0.75, alpha: 0.9)
        let data = try JSONEncoder().encode(color)
        let decoded = try JSONDecoder().decode(CodableColor.self, from: data)

        #expect(abs(decoded.red - 0.5) < 0.001)
        #expect(abs(decoded.green - 0.25) < 0.001)
        #expect(abs(decoded.blue - 0.75) < 0.001)
        #expect(abs(decoded.alpha - 0.9) < 0.001)
    }

    @Test("MarkupElementType display names are non-empty")
    func testElementTypeDisplayNames() {
        for type in MarkupElementType.allCases {
            #expect(!type.displayName.isEmpty)
        }
    }

    @Test("Default styles exist for all element types")
    func testDefaultStylesComplete() {
        // Inline types intentionally have nil fontSize — they inherit from parent block
        let inlineTypes: Set<MarkupElementType> = [.text, .emphasis, .strong, .strikethrough, .link]
        let specialTypes: Set<MarkupElementType> = [.thematicBreak, .image, .tableCell]
        for type in MarkupElementType.allCases {
            let style = DefaultStyles.style(for: type)
            if !inlineTypes.contains(type) && !specialTypes.contains(type) {
                #expect(style.fontSize != nil, "Block element \(type) should have fontSize")
            }
        }
    }
}
