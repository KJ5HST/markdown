import AppKit
import SwiftUI

// MARK: - NSView-based drawing primitives (captured by dataWithPDF unlike SwiftUI primitives)

/// Read-only NSTextView for displaying attributed strings in print/PDF output
struct StaticBlockTextView: NSViewRepresentable {
    let attributedText: NSAttributedString

    func makeNSView(context: Context) -> NSTextView {
        let textView = NSTextView()
        textView.isEditable = false
        textView.isSelectable = false
        textView.drawsBackground = false
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainerInset = .zero
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainer?.widthTracksTextView = true
        textView.textStorage?.setAttributedString(attributedText)
        return textView
    }

    func sizeThatFits(_ proposal: ProposedViewSize, nsView: NSTextView, context: Context) -> CGSize? {
        guard let layoutManager = nsView.layoutManager, let textContainer = nsView.textContainer else {
            return nil
        }
        if let width = proposal.width, width > 0 {
            textContainer.containerSize = NSSize(width: width, height: .greatestFiniteMagnitude)
        } else {
            // No width constraint (e.g. fixedSize) — allow natural single-line layout
            textContainer.containerSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude)
        }
        layoutManager.ensureLayout(for: textContainer)
        let usedRect = layoutManager.usedRect(for: textContainer)
        return CGSize(width: proposal.width ?? usedRect.width, height: usedRect.height)
    }

    func updateNSView(_ nsView: NSTextView, context: Context) {
        nsView.textStorage?.setAttributedString(attributedText)
    }
}

/// Solid color fill drawn via NSView.draw() — renders reliably in off-screen PDF capture
struct StaticColorView: NSViewRepresentable {
    let nsColor: NSColor

    func makeNSView(context: Context) -> ColorDrawingView { ColorDrawingView(fillColor: nsColor) }
    func updateNSView(_ nsView: ColorDrawingView, context: Context) { nsView.fillColor = nsColor; nsView.needsDisplay = true }

    class ColorDrawingView: NSView {
        var fillColor: NSColor
        init(fillColor: NSColor) { self.fillColor = fillColor; super.init(frame: .zero) }
        required init?(coder: NSCoder) { fatalError() }
        override func draw(_ dirtyRect: NSRect) { fillColor.setFill(); dirtyRect.fill() }
    }
}

/// Rounded-rect stroke border drawn via NSView.draw()
struct StaticBorderView: NSViewRepresentable {
    let nsColor: NSColor
    let lineWidth: CGFloat
    let cornerRadius: CGFloat

    func makeNSView(context: Context) -> BorderDrawingView {
        BorderDrawingView(strokeColor: nsColor, lineWidth: lineWidth, cornerRadius: cornerRadius)
    }
    func updateNSView(_ nsView: BorderDrawingView, context: Context) {}

    class BorderDrawingView: NSView {
        var strokeColor: NSColor
        var lineWidth: CGFloat
        var cornerRadius: CGFloat
        init(strokeColor: NSColor, lineWidth: CGFloat, cornerRadius: CGFloat) {
            self.strokeColor = strokeColor; self.lineWidth = lineWidth; self.cornerRadius = cornerRadius
            super.init(frame: .zero)
        }
        required init?(coder: NSCoder) { fatalError() }
        override func draw(_ dirtyRect: NSRect) {
            let path = NSBezierPath(roundedRect: bounds.insetBy(dx: lineWidth / 2, dy: lineWidth / 2),
                                    xRadius: cornerRadius, yRadius: cornerRadius)
            strokeColor.setStroke()
            path.lineWidth = lineWidth
            path.stroke()
        }
    }
}

// MARK: - Page layout

/// A single page containing its assigned blocks, with margins and page background
struct PrintablePageView: View {
    let blocks: [StyledBlock]
    let stylesheet: StyleSheet
    let pageSize: CGSize
    let margin: CGFloat
    var documentURL: URL? = nil

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Page background — drawn via NSView so it appears in PDF
            StaticColorView(nsColor: stylesheet.pageBackgroundColor?.nsColor ?? .white)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(blocks) { block in
                    StaticRenderedElementView(block: block, stylesheet: stylesheet, documentURL: documentURL)
                }
                Spacer(minLength: 0)
            }
            .padding(margin)
        }
        .frame(width: pageSize.width, height: pageSize.height)
        .clipped()
    }
}

/// Multi-page document — pages stacked vertically, each exactly one page tall
struct PrintableDocumentView: View {
    let pages: [[StyledBlock]]
    let stylesheet: StyleSheet
    let pageSize: CGSize
    let margin: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(pages.enumerated()), id: \.offset) { _, pageBlocks in
                PrintablePageView(
                    blocks: pageBlocks,
                    stylesheet: stylesheet,
                    pageSize: pageSize,
                    margin: margin
                )
            }
        }
    }
}

// MARK: - Static block rendering

/// Static (non-editable) version of RenderedElementView for print/PDF output.
/// All visible elements use NSView-based drawing (not SwiftUI primitives) so they
/// are captured by dataWithPDF(inside:).
struct StaticRenderedElementView: View {
    let block: StyledBlock
    let stylesheet: StyleSheet
    var documentURL: URL? = nil

    var body: some View {
        blockContent
            .padding(EdgeInsets(
                top: block.style.paddingTop ?? 0,
                leading: block.style.paddingLeading ?? 0,
                bottom: block.style.paddingBottom ?? 0,
                trailing: block.style.paddingTrailing ?? 0
            ))
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(backgroundView)
    }

    @ViewBuilder
    private var blockContent: some View {
        switch block.content {
        case .inline(let runs):
            StaticBlockTextView(attributedText: AttributedStringBuilder.build(from: runs))

        case .children(let children):
            childrenView(children)

        case .code(let language, let text):
            codeBlockView(language, text)

        case .thematicBreak:
            thematicBreakView

        case .image(let source, let alt):
            imageView(source: source, alt: alt)

        case .table(let header, let rows):
            tableView(header: header, rows: rows)

        case .listItem(let marker, let children):
            listItemView(marker: marker, children: children)
        }
    }

    // MARK: - Code Block

    private func codeBlockView(_ language: String?, _ text: String) -> some View {
        StaticBlockTextView(
            attributedText: AttributedStringBuilder.buildCodeBlock(text: text, style: block.style)
        )
        .overlay(alignment: .topTrailing) {
            if let language, !language.isEmpty {
                staticText(language, font: NSFont.systemFont(ofSize: 9), color: .secondaryLabelColor)
                    .fixedSize()
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
            }
        }
    }

    // MARK: - Children (Block Quote, Lists)

    private var isContainer: Bool {
        [.blockQuote, .orderedList, .unorderedList].contains(block.elementType)
    }

    private func childrenView(_ children: [StyledBlock]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(children) { child in
                StaticRenderedElementView(block: child, stylesheet: stylesheet, documentURL: documentURL)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(containerBackground)
        .overlay(containerBorder)
        .overlay(alignment: .leading) {
            if block.elementType == .blockQuote {
                StaticColorView(nsColor: block.style.borderColor?.nsColor ?? .gray)
                    .frame(width: block.style.borderWidth ?? 3)
            }
        }
    }

    @ViewBuilder
    private var containerBackground: some View {
        if isContainer, let bgColor = block.style.backgroundColor {
            StaticColorView(nsColor: bgColor.nsColor)
        }
    }

    @ViewBuilder
    private var containerBorder: some View {
        if isContainer, let borderColor = block.style.borderColor, block.elementType != .blockQuote {
            StaticBorderView(
                nsColor: borderColor.nsColor,
                lineWidth: block.style.borderWidth ?? 1,
                cornerRadius: block.style.cornerRadius ?? 0
            )
        }
    }

    // MARK: - List Item

    private func listItemView(marker: String, children: [StyledBlock]) -> some View {
        HStack(alignment: .top, spacing: 6) {
            listMarkerView(marker)
                .padding(.top, children.first?.style.paddingTop ?? 0)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(children) { child in
                    StaticRenderedElementView(block: child, stylesheet: stylesheet, documentURL: documentURL)
                }
            }
        }
    }

    /// Renders the list marker (bullet, number, checkbox) via NSTextView so it appears in PDF.
    /// Matches the first child paragraph's line height so baselines align.
    private func listMarkerView(_ marker: String) -> some View {
        let font = block.style.resolvedNSFont
        let paraStyle = NSMutableParagraphStyle()
        paraStyle.alignment = .right
        // Match the line height of the paragraph text next to it
        if let spacing = block.style.lineSpacing, spacing > 0 {
            let naturalHeight = font.ascender - font.descender + font.leading
            let desired = naturalHeight + spacing
            paraStyle.minimumLineHeight = desired
            paraStyle.maximumLineHeight = desired
        }
        var attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paraStyle,
            .foregroundColor: block.style.foregroundColor?.nsColor ?? NSColor.black,
        ]
        if let kern = block.style.letterSpacing {
            attrs[.kern] = kern
        }
        return StaticBlockTextView(
            attributedText: NSAttributedString(string: marker, attributes: attrs)
        )
        .frame(width: 20)
    }

    // MARK: - Thematic Break

    private var thematicBreakView: some View {
        StaticColorView(nsColor: block.style.foregroundColor?.nsColor ?? .gray)
            .frame(height: block.style.borderWidth ?? 1)
    }

    // MARK: - Image

    private func resolveImageURL(_ source: String) -> URL? {
        if let url = URL(string: source), url.scheme != nil {
            return url
        }
        if let fileURL = documentURL {
            let dir = fileURL.deletingLastPathComponent().path
            let resolvedPath = (dir as NSString).appendingPathComponent(source)
            if FileManager.default.fileExists(atPath: resolvedPath) {
                return URL(fileURLWithPath: resolvedPath)
            }
        }
        let cwdPath = (FileManager.default.currentDirectoryPath as NSString).appendingPathComponent(source)
        if FileManager.default.fileExists(atPath: cwdPath) {
            return URL(fileURLWithPath: cwdPath)
        }
        return nil
    }

    private func imageView(source: String, alt: String) -> some View {
        VStack {
            if let url = resolveImageURL(source) {
                if url.isFileURL {
                    if let nsImage = NSImage(contentsOf: url) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(block.style.cornerRadius ?? 0)
                            .frame(maxHeight: 400)
                    } else {
                        staticText(alt.isEmpty ? "Image failed to load" : alt,
                                   font: .systemFont(ofSize: 12), color: .secondaryLabelColor)
                    }
                } else {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .cornerRadius(block.style.cornerRadius ?? 0)
                        case .failure:
                            staticText(alt.isEmpty ? "Image failed to load" : alt,
                                       font: .systemFont(ofSize: 12), color: .secondaryLabelColor)
                        case .empty:
                            ProgressView()
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(maxHeight: 400)
                }
            } else {
                staticText(alt.isEmpty ? "Invalid image URL" : alt,
                           font: .systemFont(ofSize: 12), color: .secondaryLabelColor)
            }
        }
    }

    // MARK: - Table (all lines drawn via NSView so they appear in PDF)

    private func tableView(header: [StyledTableCell], rows: [[StyledTableCell]]) -> some View {
        let lineNSColor = block.style.borderColor?.nsColor ?? NSColor.gray.withAlphaComponent(0.3)
        let lineWidth = block.style.borderWidth ?? 1
        let cornerRadius = block.style.cornerRadius ?? 0

        return VStack(spacing: 0) {
            // Header row
            tableRow(cells: header, lineNSColor: lineNSColor, lineWidth: lineWidth)
                .background(StaticColorView(nsColor: header.first?.style.backgroundColor?.nsColor ?? .clear))

            // Header separator
            StaticColorView(nsColor: lineNSColor).frame(height: lineWidth)

            // Body rows
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                tableRow(cells: row, lineNSColor: lineNSColor, lineWidth: lineWidth)
                StaticColorView(nsColor: lineNSColor).frame(height: lineWidth)
            }
        }
        .overlay(StaticBorderView(nsColor: lineNSColor, lineWidth: lineWidth, cornerRadius: cornerRadius))
    }

    private func tableRow(cells: [StyledTableCell], lineNSColor: NSColor, lineWidth: CGFloat) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(cells.enumerated()), id: \.element.id) { col, cell in
                if col > 0 {
                    StaticColorView(nsColor: lineNSColor).frame(width: lineWidth)
                }
                StaticBlockTextView(attributedText: AttributedStringBuilder.build(from: cell.runs))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(EdgeInsets(
                        top: cell.style.paddingTop ?? 4,
                        leading: cell.style.paddingLeading ?? 8,
                        bottom: cell.style.paddingBottom ?? 4,
                        trailing: cell.style.paddingTrailing ?? 8
                    ))
                    .background(StaticColorView(nsColor: cell.style.backgroundColor?.nsColor ?? .clear))
            }
        }
    }

    // MARK: - Background

    @ViewBuilder
    private var backgroundView: some View {
        if !isContainer, let bgColor = block.style.backgroundColor {
            StaticColorView(nsColor: bgColor.nsColor)
        }
    }

    // MARK: - Helper

    /// Renders a short label via NSTextView (instead of SwiftUI Text which doesn't appear in PDF)
    private func staticText(_ string: String, font: NSFont, color: NSColor) -> some View {
        StaticBlockTextView(
            attributedText: NSAttributedString(string: string, attributes: [
                .font: font,
                .foregroundColor: color,
            ])
        )
    }
}
