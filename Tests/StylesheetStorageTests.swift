import Testing
import Foundation
@testable import MarkDownApp

@Suite("StylesheetStorage Tests")
struct StylesheetStorageTests {

    private func makeTempStorage() -> (StylesheetStorage, URL) {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("MarkDownTests-\(UUID().uuidString)", isDirectory: true)
        let storage = StylesheetStorage(directory: tempDir)
        return (storage, tempDir)
    }

    private func cleanup(_ dir: URL) {
        try? FileManager.default.removeItem(at: dir)
    }

    @Test("Save and load stylesheet")
    func testSaveAndLoad() {
        let (storage, tempDir) = makeTempStorage()
        defer { cleanup(tempDir) }

        var sheet = StyleSheet(name: "Test Storage", description: "For testing")
        sheet.setStyle(
            ElementStyle(fontSize: 28, fontWeight: .bold),
            for: .heading1
        )

        storage.save(sheet)

        let loaded = storage.load(id: sheet.id)
        #expect(loaded != nil)
        #expect(loaded?.name == "Test Storage")
        #expect(loaded?.styles[.heading1]?.fontSize == 28)

        // Cleanup
        storage.delete(sheet)
        let afterDelete = storage.load(id: sheet.id)
        #expect(afterDelete == nil)
    }

    @Test("Load all returns saved stylesheets")
    func testLoadAll() {
        let (storage, tempDir) = makeTempStorage()
        defer { cleanup(tempDir) }

        let sheet1 = StyleSheet(name: "Sheet A")
        let sheet2 = StyleSheet(name: "Sheet B")

        storage.save(sheet1)
        storage.save(sheet2)

        let all = storage.loadAll()
        let ids = all.map(\.id)
        #expect(ids.contains(sheet1.id))
        #expect(ids.contains(sheet2.id))
    }

    @Test("JSON output is human-readable")
    func testJSONReadability() throws {
        var sheet = StyleSheet(name: "Readable", author: "Test")
        sheet.setStyle(
            ElementStyle(fontSize: 16, foregroundColor: .blue),
            for: .paragraph
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(sheet)
        let jsonString = String(data: data, encoding: .utf8)!

        #expect(jsonString.contains("\"name\""))
        #expect(jsonString.contains("\"Readable\""))
        #expect(jsonString.contains("\"paragraph\""))
        #expect(jsonString.contains("\n")) // pretty-printed has newlines
    }
}
