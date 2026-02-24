import Testing
import Foundation
@testable import MarkDownApp

@Suite("DocumentViewModel Tests")
struct DocumentViewModelTests {

    @MainActor
    @Test("Load document does not mark as dirty")
    func testLoadDocumentNotDirty() throws {
        let vm = DocumentViewModel()

        // Create a temp file to load
        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent("test-\(UUID().uuidString).md")
        try "# Hello\n\nWorld".write(to: tempFile, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempFile) }

        vm.loadDocument(from: tempFile)

        #expect(vm.document.isDirty == false)
        #expect(vm.sourceText == "# Hello\n\nWorld")
    }

    @MainActor
    @Test("Update block source modifies sourceText")
    func testUpdateBlockSource() {
        let vm = DocumentViewModel()
        vm.sourceText = "Hello world"
        vm.rerender()

        guard let block = vm.styledBlocks.first else {
            Issue.record("No blocks rendered")
            return
        }

        vm.updateBlockSource(block, newMarkdown: "Hello universe")
        #expect(vm.sourceText == "Hello universe")
    }

    @MainActor
    @Test("Finish editing increments renderVersion")
    func testFinishEditingRerenders() async {
        let vm = DocumentViewModel()
        let initialVersion = vm.renderVersion

        // Simulate editing
        if let block = vm.styledBlocks.first {
            vm.editingBlockId = block.id
            vm.finishEditing(blockId: block.id)
        }

        // finishEditing defers rerender to next run loop iteration
        await MainActor.run {}

        #expect(vm.renderVersion > initialVersion)
    }

    @MainActor
    @Test("sourceIndex handles empty string")
    func testSourceIndexEmpty() {
        let vm = DocumentViewModel()
        vm.sourceText = ""
        // Line 1, column 1 should be endIndex for empty string
        let idx = vm.sourceIndex(line: 1, column: 1)
        #expect(idx == vm.sourceText.endIndex)
    }

    @MainActor
    @Test("sourceIndex handles EOF position")
    func testSourceIndexEOF() {
        let vm = DocumentViewModel()
        vm.sourceText = "AB"
        // After 'B': line 1, column 3
        let idx = vm.sourceIndex(line: 1, column: 3)
        #expect(idx == vm.sourceText.endIndex)
    }

    @MainActor
    @Test("sourceIndex handles multiline")
    func testSourceIndexMultiline() {
        let vm = DocumentViewModel()
        vm.sourceText = "AB\nCD"
        // 'C' is at line 2, column 1
        let idx = vm.sourceIndex(line: 2, column: 1)
        #expect(idx != nil)
        if let idx = idx {
            #expect(vm.sourceText[idx] == "C")
        }
    }

    @MainActor
    @Test("Save error is published on write failure")
    func testSaveErrorOnFailure() {
        let vm = DocumentViewModel()
        // Set a file URL to a non-writable location
        vm.document.fileURL = URL(fileURLWithPath: "/nonexistent/path/file.md")
        vm.saveDocument()
        #expect(vm.saveError != nil)
    }
}
