import Foundation
import AppKit
import UniformTypeIdentifiers

/// Handles opening and saving markdown files
enum DocumentStorage {
    static func openMarkdownFile(completion: @escaping (URL?) -> Void) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [
            UTType(filenameExtension: "md") ?? .plainText,
            UTType(filenameExtension: "markdown") ?? .plainText,
            .plainText
        ]
        panel.allowsMultipleSelection = false
        panel.message = "Open a Markdown file"

        panel.begin { response in
            guard response == .OK else {
                completion(nil)
                return
            }
            completion(panel.url)
        }
    }

    static func saveMarkdownFile(source: String, completion: @escaping (URL?) -> Void) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [
            UTType(filenameExtension: "md") ?? .plainText
        ]
        panel.nameFieldStringValue = "Untitled.md"
        panel.message = "Save Markdown file"

        panel.begin { response in
            guard response == .OK, let url = panel.url else {
                completion(nil)
                return
            }
            do {
                try source.write(to: url, atomically: true, encoding: .utf8)
                completion(url)
            } catch {
                completion(nil)
            }
        }
    }
}
