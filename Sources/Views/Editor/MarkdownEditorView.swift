import SwiftUI

/// Monospaced text editor for markdown source with scroll sync support
struct MarkdownEditorView: View {
    @Binding var source: String
    var isActivePane: Bool
    @Binding var scrollFraction: CGFloat

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

            SourceTextView(
                text: $source,
                isActivePane: isActivePane,
                scrollFraction: $scrollFraction
            )
            .padding(4)
        }
    }
}
