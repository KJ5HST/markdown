import SwiftUI
import AppKit

enum ScrollPane {
    case source, preview
}

struct ContentView: View {
    @EnvironmentObject var documentVM: DocumentViewModel
    @State private var editorFraction: CGFloat = 0.0
    @State private var lastManualFraction: CGFloat = 0.5
    @State private var dividerHovered = false
    @State private var scrollFraction: CGFloat = 0
    @State private var activeScrollPane: ScrollPane = .preview

    var body: some View {
        VStack(spacing: 0) {
            StyleToolbar()
                .environmentObject(documentVM)

            GeometryReader { geo in
                let totalHeight = geo.size.height
                let dividerHeight: CGFloat = 10
                let editorHeight = max(30, editorFraction * totalHeight)
                let previewHeight = max(10, totalHeight - editorHeight - dividerHeight)

                VStack(spacing: 0) {
                    MarkdownPreviewView(
                        isActivePane: activeScrollPane == .preview,
                        scrollFraction: $scrollFraction
                    )
                        .environmentObject(documentVM)
                        .frame(height: previewHeight)
                        .onHover { hovering in
                            if hovering { activeScrollPane = .preview }
                        }

                // Draggable divider
                ZStack {
                    Rectangle()
                        .fill(dividerHovered
                              ? Color.accentColor.opacity(0.2)
                              : Color(nsColor: .separatorColor))
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(dividerHovered
                              ? Color.accentColor.opacity(0.6)
                              : Color.secondary.opacity(0.5))
                        .frame(width: 36, height: 3)
                }
                .frame(height: dividerHeight)
                .contentShape(Rectangle())
                .onHover { hovering in
                    guard hovering != dividerHovered else { return }
                    dividerHovered = hovering
                    if hovering {
                        NSCursor.resizeUpDown.push()
                    } else {
                        NSCursor.pop()
                    }
                }
                .onDisappear {
                    if dividerHovered {
                        NSCursor.pop()
                        dividerHovered = false
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 1)
                        .onChanged { value in
                            let newPreviewHeight = previewHeight + value.translation.height
                            let clampedPreview = min(max(10, newPreviewHeight), totalHeight - 30 - dividerHeight)
                            editorFraction = 1 - (clampedPreview / totalHeight) - (dividerHeight / totalHeight)
                        }
                )

                MarkdownEditorView(
                    source: $documentVM.sourceText,
                    isActivePane: activeScrollPane == .source,
                    scrollFraction: $scrollFraction
                )
                    .frame(height: editorHeight)
                    .onHover { hovering in
                        if hovering { activeScrollPane = .source }
                    }
                }
            }
        }
        .sheet(isPresented: $documentVM.showStylesheetBrowser) {
            StylesheetBrowserView()
                .environmentObject(documentVM)
                .frame(minWidth: 500, minHeight: 400)
        }
        .alert("Save Error", isPresented: Binding(
            get: { documentVM.saveError != nil },
            set: { if !$0 { documentVM.saveError = nil } }
        )) {
            Button("OK") { documentVM.saveError = nil }
        } message: {
            Text(documentVM.saveError ?? "")
        }
        .onChange(of: documentVM.sourceVisible) { _, visible in
            withAnimation(.easeInOut(duration: 0.2)) {
                if visible {
                    editorFraction = lastManualFraction
                } else {
                    if editorFraction > 0 {
                        lastManualFraction = editorFraction
                    }
                    editorFraction = 0.0
                }
            }
        }
    }
}
