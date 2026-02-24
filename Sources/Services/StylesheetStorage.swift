import Foundation
import AppKit

/// Handles JSON persistence of stylesheets to ~/Library/Application Support/MarkDown/stylesheets/
class StylesheetStorage {
    static let shared = StylesheetStorage()

    private let fileManager = FileManager.default
    private let encoder: JSONEncoder = {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        enc.dateEncodingStrategy = .iso8601
        return enc
    }()
    private let decoder: JSONDecoder = {
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        return dec
    }()

    let baseDirectory: URL

    init(directory: URL? = nil) {
        if let directory = directory {
            self.baseDirectory = directory
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            self.baseDirectory = appSupport.appendingPathComponent("MarkDown/stylesheets", isDirectory: true)
        }
        try? fileManager.createDirectory(at: baseDirectory, withIntermediateDirectories: true)
    }

    // MARK: - CRUD

    func save(_ stylesheet: StyleSheet) {
        let url = baseDirectory.appendingPathComponent("\(stylesheet.id.uuidString).json")
        guard let data = try? encoder.encode(stylesheet) else { return }
        try? data.write(to: url, options: .atomic)
    }

    func loadAll() -> [StyleSheet] {
        guard let urls = try? fileManager.contentsOfDirectory(
            at: baseDirectory,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        ) else { return [] }

        return urls
            .filter { $0.pathExtension == "json" }
            .compactMap { url -> StyleSheet? in
                guard let data = try? Data(contentsOf: url) else { return nil }
                return try? decoder.decode(StyleSheet.self, from: data)
            }
            .sorted { $0.createdAt < $1.createdAt }
    }

    func load(id: UUID) -> StyleSheet? {
        let url = baseDirectory.appendingPathComponent("\(id.uuidString).json")
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? decoder.decode(StyleSheet.self, from: data)
    }

    func delete(_ stylesheet: StyleSheet) {
        let url = baseDirectory.appendingPathComponent("\(stylesheet.id.uuidString).json")
        try? fileManager.removeItem(at: url)
    }

    // MARK: - Import/Export

    func importStylesheet(completion: @escaping (StyleSheet?) -> Void) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.message = "Select a stylesheet JSON file to import"

        panel.begin { response in
            guard response == .OK, let url = panel.url else {
                completion(nil)
                return
            }
            guard let data = try? Data(contentsOf: url),
                  var stylesheet = try? self.decoder.decode(StyleSheet.self, from: data) else {
                completion(nil)
                return
            }
            // Assign a new ID to avoid conflicts
            stylesheet.id = UUID()
            // Validate imported styles
            for (elementType, style) in stylesheet.styles {
                stylesheet.styles[elementType] = style.validated()
            }
            self.save(stylesheet)
            completion(stylesheet)
        }
    }

    func exportStylesheet(_ stylesheet: StyleSheet) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "\(stylesheet.name).json"
        panel.message = "Export stylesheet as JSON"

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            guard let data = try? self.encoder.encode(stylesheet) else { return }
            try? data.write(to: url, options: .atomic)
        }
    }
}
