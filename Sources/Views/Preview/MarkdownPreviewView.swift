import SwiftUI

/// Renders the list of styled blocks as the markdown preview
struct MarkdownPreviewView: View {
    @EnvironmentObject var documentVM: DocumentViewModel

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(documentVM.styledBlocks) { block in
                        RenderedElementView(block: block)
                            .id(block.id)
                    }
                }
                .padding(16)
                .padding(.bottom, 40)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .onChange(of: documentVM.scrollToAnchor) { _, anchor in
                guard let anchor else { return }
                documentVM.scrollToAnchor = nil
                if let blockId = documentVM.blockId(forAnchor: anchor) {
                    withAnimation {
                        proxy.scrollTo(blockId, anchor: .top)
                    }
                }
            }
        }
        .background(documentVM.stylesheet.pageBackgroundColor?.color ?? Color.white)
    }
}
