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

    /// Reference to document view model for unsaved-changes checks
    weak var documentVM: DocumentViewModel?

    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first else { return }
        if let handler = onOpenFile {
            handler(url)
        } else {
            pendingURL = url
        }
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard let documentVM = documentVM, documentVM.document.isDirty else {
            return .terminateNow
        }
        guard let window = NSApp.keyWindow ?? NSApp.mainWindow ?? NSApp.windows.first(where: { $0.isVisible }) else {
            return .terminateNow
        }
        showUnsavedChangesAlert(on: window, documentVM: documentVM) { shouldProceed in
            NSApp.reply(toApplicationShouldTerminate: shouldProceed)
        }
        return .terminateLater
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
                .background(WindowAccessor(documentVM: documentVM, isDocumentEdited: documentVM.document.isDirty))
                .onAppear {
                    appDelegate.onOpenFile = { url in
                        documentVM.withSaveCheck {
                            documentVM.loadDocument(from: url)
                        }
                    }
                    appDelegate.documentVM = documentVM
                }
                .onOpenURL { url in
                    documentVM.withSaveCheck {
                        documentVM.loadDocument(from: url)
                    }
                }
        }
        .commands {
            AppCommands(documentVM: documentVM)
        }
    }
}

// MARK: - Window Close Handling

/// Invisible view that installs an NSWindowDelegate to intercept window close
struct WindowAccessor: NSViewRepresentable {
    let documentVM: DocumentViewModel
    /// Observed so SwiftUI calls updateNSView when dirty state changes
    var isDocumentEdited: Bool

    func makeCoordinator() -> WindowCloseDelegate {
        WindowCloseDelegate(documentVM: documentVM)
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.setFrameSize(.zero)
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.delegate = context.coordinator
            window.isDocumentEdited = self.isDocumentEdited
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        nsView.window?.isDocumentEdited = isDocumentEdited
    }
}

class WindowCloseDelegate: NSObject, NSWindowDelegate {
    let documentVM: DocumentViewModel
    private var allowClose = false

    init(documentVM: DocumentViewModel) {
        self.documentVM = documentVM
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        if allowClose { return true }
        guard documentVM.document.isDirty else { return true }

        showUnsavedChangesAlert(on: sender, documentVM: documentVM) { [weak self] shouldClose in
            guard shouldClose else { return }
            self?.allowClose = true
            sender.close()
            self?.allowClose = false
        }

        return false
    }
}

// MARK: - Unsaved Changes Alert

/// Present a standard macOS "Save / Don't Save / Cancel" alert as a sheet
@MainActor func showUnsavedChangesAlert(
    on window: NSWindow,
    documentVM: DocumentViewModel,
    completion: @escaping (Bool) -> Void
) {
    let alert = NSAlert()
    alert.messageText = "Do you want to save the changes made to \"\(documentVM.document.displayName)\"?"
    alert.informativeText = "Your changes will be lost if you don't save them."
    alert.alertStyle = .warning
    alert.addButton(withTitle: "Save")
    alert.addButton(withTitle: "Don't Save")
    alert.addButton(withTitle: "Cancel")

    alert.beginSheetModal(for: window) { response in
        switch response {
        case .alertFirstButtonReturn: // Save
            if let url = documentVM.document.fileURL {
                do {
                    try documentVM.sourceText.write(to: url, atomically: true, encoding: .utf8)
                    documentVM.document.isDirty = false
                    completion(true)
                } catch {
                    completion(false)
                }
            } else {
                DocumentStorage.saveMarkdownFile(source: documentVM.sourceText) { url in
                    if let url = url {
                        documentVM.document.fileURL = url
                        documentVM.document.isDirty = false
                        completion(true)
                    } else {
                        completion(false)
                    }
                }
            }
        case .alertSecondButtonReturn: // Don't Save
            completion(true)
        default: // Cancel
            completion(false)
        }
    }
}
