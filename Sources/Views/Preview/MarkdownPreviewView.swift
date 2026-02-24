import SwiftUI

/// Renders the list of styled blocks as the markdown preview
struct MarkdownPreviewView: View {
    @EnvironmentObject var documentVM: DocumentViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(documentVM.styledBlocks) { block in
                    RenderedElementView(block: block)
                }
            }
            .padding(16)
            .padding(.bottom, 40)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(documentVM.stylesheet.pageBackgroundColor?.color ?? Color.white)
    }
}
