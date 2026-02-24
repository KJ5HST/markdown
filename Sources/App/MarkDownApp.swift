import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    /// Buffered URL received before the SwiftUI view was ready
    var pendingURL: URL?
    var onOpenFile: ((URL) -> Void)? {
        didSet {
            // Replay any URL that arrived before the callback was set
            if let url = pendingURL, let handler = onOpenFile {
                pendingURL = nil
                handler(url)
            }
        }
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first else { return }
        if let handler = onOpenFile {
            handler(url)
        } else {
            pendingURL = url
        }
    }
}

@main
struct MarkDownApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var documentVM = DocumentViewModel()

    init() {
        // Ensure the process is treated as a regular GUI app (needed when running
        // as a bare executable outside of a .app bundle) so that cursors, menu bar,
        // Dock icon, and activation all work correctly.
        NSApplication.shared.setActivationPolicy(.regular)
        ProcessInfo.processInfo.processName = "MarkDown"
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(documentVM)
                .frame(minWidth: 700, minHeight: 500)
                .onAppear {
                    appDelegate.onOpenFile = { url in
                        documentVM.loadDocument(from: url)
                    }
                }
                .onOpenURL { url in
                    documentVM.loadDocument(from: url)
                }
        }
        .commands {
            AppCommands(documentVM: documentVM)
        }
    }
}
