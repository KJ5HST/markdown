import Foundation

private let logURL = FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent("markdown-debug.log")

func debugLog(_ message: String) {
    #if DEBUG
    let line = "\(Date()): \(message)\n"
    if let data = line.data(using: .utf8) {
        if FileManager.default.fileExists(atPath: logURL.path) {
            if let handle = try? FileHandle(forWritingTo: logURL) {
                defer { try? handle.close() }
                handle.seekToEndOfFile()
                handle.write(data)
            }
        } else {
            try? data.write(to: logURL)
        }
    }
    #endif
}
