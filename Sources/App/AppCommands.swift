import SwiftUI

struct AppCommands: Commands {
    @ObservedObject var documentVM: DocumentViewModel

    var body: some Commands {
        // MARK: - File Menu

        CommandGroup(replacing: .newItem) {
            Button("New") {
                documentVM.newDocument()
            }
            .keyboardShortcut("n", modifiers: .command)

            Button("Open...") {
                DocumentStorage.openMarkdownFile { url in
                    guard let url = url else { return }
                    documentVM.loadDocument(from: url)
                }
            }
            .keyboardShortcut("o", modifiers: .command)
        }

        CommandGroup(after: .newItem) {
            Divider()

            Button("Save") {
                documentVM.saveDocument()
            }
            .keyboardShortcut("s", modifiers: .command)

            Button("Save As...") {
                DocumentStorage.saveMarkdownFile(source: documentVM.sourceText) { url in
                    if let url = url {
                        documentVM.document.fileURL = url
                        documentVM.document.isDirty = false
                    }
                }
            }
            .keyboardShortcut("s", modifiers: [.command, .shift])

            Button("Revert to Saved") {
                documentVM.revertToSaved()
            }
            .disabled(documentVM.document.fileURL == nil || !documentVM.document.isDirty)
        }

        CommandGroup(replacing: .printItem) {
            Button("Export as PDF...") {
                documentVM.exportPDF()
            }

            Divider()

            Button("Print...") {
                documentVM.printDocument()
            }
            .keyboardShortcut("p", modifiers: .command)
        }

        // MARK: - Find Menu

        CommandGroup(after: .textEditing) {
            Divider()

            Button("Find") {
                documentVM.findReplace.isVisible = true
                documentVM.findReplace.showReplace = false
            }
            .keyboardShortcut("f", modifiers: .command)

            Button("Find and Replace") {
                documentVM.findReplace.isVisible = true
                documentVM.findReplace.showReplace = true
            }
            .keyboardShortcut("f", modifiers: [.command, .option])
        }

        // MARK: - Format Menu

        CommandMenu("Format") {
            Button("Bold") {
                documentVM.toggleInlineFormatting(syntax: "**")
            }
            .keyboardShortcut("b", modifiers: .command)

            Button("Italic") {
                documentVM.toggleInlineFormatting(syntax: "*")
            }
            .keyboardShortcut("i", modifiers: .command)

            Button("Strikethrough") {
                documentVM.toggleInlineFormatting(syntax: "~~")
            }
            .keyboardShortcut("x", modifiers: [.command, .shift])

            Button("Code") {
                documentVM.toggleInlineFormatting(syntax: "`")
            }
            .keyboardShortcut("c", modifiers: [.command, .shift])
        }

        // MARK: - View Menu

        CommandMenu("View") {
            Button(documentVM.sourceVisible ? "Hide Source" : "Show Source") {
                documentVM.sourceVisible.toggle()
            }
            .keyboardShortcut(.return, modifiers: [.command, .shift])
        }

        // MARK: - Stylesheet Menu

        CommandMenu("Stylesheet") {
            Button("Import Stylesheet...") {
                StylesheetStorage.shared.importStylesheet { stylesheet in
                    if let stylesheet = stylesheet {
                        documentVM.stylesheet = stylesheet
                        documentVM.rerender()
                    }
                }
            }
            .keyboardShortcut("i", modifiers: [.command, .shift])

            Button("Export Stylesheet...") {
                StylesheetStorage.shared.exportStylesheet(documentVM.stylesheet)
            }

            Divider()

            Button("Manage Stylesheets...") {
                documentVM.showStylesheetBrowser = true
            }

            Divider()

            Button("Reset to Default") {
                documentVM.resetStylesheet()
            }
        }
    }
}
