import SwiftUI

/// Renders the list of styled blocks as the markdown preview
struct MarkdownPreviewView: View {
    @EnvironmentObject var documentVM: DocumentViewModel
    var isActivePane: Bool
    @Binding var scrollFraction: CGFloat

    @State private var scrollPosition = ScrollPosition(edge: .top)
    @State private var contentHeight: CGFloat = 0
    @State private var containerHeight: CGFloat = 0

    var body: some View {
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
        .scrollPosition($scrollPosition)
        .onScrollGeometryChange(for: ScrollGeometryData.self) { geometry in
            ScrollGeometryData(
                offset: geometry.contentOffset.y,
                contentHeight: geometry.contentSize.height,
                containerHeight: geometry.containerSize.height
            )
        } action: { _, data in
            contentHeight = data.contentHeight
            containerHeight = data.containerHeight

            guard isActivePane else { return }
            let maxScroll = max(1, data.contentHeight - data.containerHeight)
            let fraction = max(0, min(1, data.offset / maxScroll))
            scrollFraction = fraction
        }
        .onChange(of: scrollFraction) { _, fraction in
            guard !isActivePane else { return }
            let maxScroll = max(0, contentHeight - containerHeight)
            guard maxScroll > 0 else { return }
            scrollPosition.scrollTo(y: fraction * maxScroll)
        }
        .onChange(of: documentVM.scrollToAnchor) { _, anchor in
            guard let anchor else { return }
            documentVM.scrollToAnchor = nil
            if let blockId = documentVM.blockId(forAnchor: anchor) {
                withAnimation {
                    scrollPosition.scrollTo(id: blockId, anchor: .top)
                }
            }
        }
        .background(documentVM.stylesheet.pageBackgroundColor?.color ?? Color.white)
    }
}

private struct ScrollGeometryData: Equatable {
    let offset: CGFloat
    let contentHeight: CGFloat
    let containerHeight: CGFloat
}
