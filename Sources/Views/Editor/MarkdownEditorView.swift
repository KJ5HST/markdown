import SwiftUI

/// Monospaced text editor for markdown source
struct MarkdownEditorView: View {
    @Binding var source: String

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Source")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                Spacer()
            }
            .background(Color(nsColor: .windowBackgroundColor))

            TextEditor(text: $source)
                .font(.system(size: 13, design: .monospaced))
                .scrollContentBackground(.visible)
                .padding(4)
        }
    }
}
