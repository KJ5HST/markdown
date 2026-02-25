import SwiftUI
import AppKit

/// Wraps a rendered block element with hover highlight and tap-to-edit popover
struct RenderedElementView: View {
    let block: StyledBlock
    @EnvironmentObject var documentVM: DocumentViewModel

    private var styledContent: some View {
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

    var body: some View {
        styledContent
    }

    @ViewBuilder
    private var blockContent: some View {
        switch block.content {
        case .inline(let runs):
            inlineRunsView(runs)

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

    // MARK: - Inline Runs

    private func inlineRunsView(_ runs: [StyledRun]) -> some View {
        EditableBlockTextView(
            attributedText: AttributedStringBuilder.build(from: runs),
            blockId: block.id,
            onTextChange: { edited in
                debugLog("onTextChange called for \(block.elementType), sourcePos=\(String(describing: block.sourcePosition))")
                let md = MarkdownReconstructor.reconstruct(edited, elementType: block.elementType)
                debugLog("reconstructed markdown: \(md.prefix(80))")
                documentVM.updateBlockSource(block, newMarkdown: md)
            },
            onFocus: { textView in
                documentVM.editingBlockId = block.id
                documentVM.activeTextView = textView
            },
            onBlur: { documentVM.finishEditing(blockId: block.id) },
            onSelectionChange: { textView in
                documentVM.updateSelectionSyntaxStack(from: textView)
            },
            onNavigateUp: { documentVM.navigateToPreviousBlock(from: block.id) },
            onNavigateDown: { documentVM.navigateToNextBlock(from: block.id) },
            onAnchorTap: { anchor in documentVM.scrollToAnchor = anchor }
        )
    }

    private func styledText(for run: StyledRun) -> Text {
        // Links use AttributedString so SwiftUI handles URL opening
        if run.elementType == .link, let dest = run.destination, let url = URL(string: dest) {
            var attrString = AttributedString(run.text)
            attrString.link = url
            attrString.font = run.style.resolvedFont
            if let color = run.style.foregroundColor {
                attrString.foregroundColor = color.color
            }
            attrString.underlineStyle = .single
            return Text(attrString)
        }

        var text = Text(run.text)

        text = text.font(run.style.resolvedFont)

        if let color = run.style.foregroundColor {
            text = text.foregroundColor(color.color)
        }

        if run.elementType == .strikethrough {
            text = text.strikethrough()
        }

        return text
    }

    // MARK: - Code Block

    private func codeBlockView(_ language: String?, _ text: String) -> some View {
        ZStack(alignment: .topTrailing) {
            EditableBlockTextView(
                attributedText: AttributedStringBuilder.buildCodeBlock(text: text, style: block.style),
                isCodeBlock: true,
                blockId: block.id,
                onTextChange: { edited in
                    let md = MarkdownReconstructor.reconstruct(edited, elementType: .codeBlock, language: language)
                    documentVM.updateBlockSource(block, newMarkdown: md)
                },
                onFocus: { textView in
                    documentVM.editingBlockId = block.id
                    documentVM.activeTextView = textView
                },
                onBlur: { documentVM.finishEditing(blockId: block.id) },
                onNavigateUp: { documentVM.navigateToPreviousBlock(from: block.id) },
                onNavigateDown: { documentVM.navigateToNextBlock(from: block.id) }
            )

            if let language, !language.isEmpty {
                Text(language)
                    .font(.caption2)
                    .foregroundColor(.secondary)
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
                RenderedElementView(block: child)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(containerBackground)
        .overlay(containerBorder)
        .overlay(alignment: .leading) {
            if block.elementType == .blockQuote {
                blockQuoteAccentBar
            }
        }
    }

    @ViewBuilder
    private var containerBackground: some View {
        if isContainer, let bgColor = block.style.backgroundColor {
            RoundedRectangle(cornerRadius: block.style.cornerRadius ?? 0)
                .fill(bgColor.color)
        }
    }

    @ViewBuilder
    private var containerBorder: some View {
        if isContainer, let borderColor = block.style.borderColor, block.elementType != .blockQuote {
            RoundedRectangle(cornerRadius: block.style.cornerRadius ?? 0)
                .stroke(borderColor.color, lineWidth: block.style.borderWidth ?? 1)
                .allowsHitTesting(false)
        }
    }

    private var blockQuoteAccentBar: some View {
        UnevenRoundedRectangle(
            topLeadingRadius: block.style.cornerRadius ?? 0,
            bottomLeadingRadius: block.style.cornerRadius ?? 0
        )
        .fill(block.style.borderColor?.color ?? Color.gray)
        .frame(width: block.style.borderWidth ?? 3)
    }

    // MARK: - List Item

    private func listItemView(marker: String, children: [StyledBlock]) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text(marker)
                .font(block.style.resolvedFont)
                .foregroundColor(block.style.foregroundColor?.color ?? .primary)
                .frame(width: 20, alignment: .trailing)
                .padding(.top, children.first?.style.paddingTop ?? 0)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(children) { child in
                    RenderedElementView(block: child)
                }
            }
        }
    }

    // MARK: - Thematic Break

    private var thematicBreakView: some View {
        Rectangle()
            .fill(block.style.foregroundColor?.color ?? Color.gray)
            .frame(height: block.style.borderWidth ?? 1)
    }

    // MARK: - Image

    /// Resolve an image source string to a URL, handling both absolute URLs and
    /// paths relative to the current document's directory.
    private func resolveImageURL(_ source: String) -> URL? {
        // Absolute URL (https://, http://, file://)
        if let url = URL(string: source), url.scheme != nil {
            return url
        }
        // Relative path — resolve against the document's directory
        if let fileURL = documentVM.document.fileURL {
            let dir = fileURL.deletingLastPathComponent().path
            let resolvedPath = (dir as NSString).appendingPathComponent(source)
            if FileManager.default.fileExists(atPath: resolvedPath) {
                return URL(fileURLWithPath: resolvedPath)
            }
        }
        // Fallback: try relative to the current working directory
        let cwdPath = (FileManager.default.currentDirectoryPath as NSString).appendingPathComponent(source)
        if FileManager.default.fileExists(atPath: cwdPath) {
            return URL(fileURLWithPath: cwdPath)
        }
        return nil
    }

    private func imageView(source: String, alt: String) -> some View {
        LocalImageView(
            url: resolveImageURL(source),
            alt: alt,
            cornerRadius: block.style.cornerRadius ?? 0
        )
    }
}

/// Loads local images synchronously (fast for file URLs) and uses AsyncImage for remote URLs
private struct LocalImageView: View {
    let url: URL?
    let alt: String
    let cornerRadius: CGFloat

    var body: some View {
        if let url = url, url.isFileURL, let nsImage = NSImage(contentsOf: url) {
            let size = nsImage.size
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: size.width, maxHeight: min(size.height, 400))
                .cornerRadius(cornerRadius)
        } else if let url = url, !url.isFileURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(cornerRadius)
                case .failure:
                    failureLabel
                case .empty:
                    ProgressView()
                @unknown default:
                    EmptyView()
                }
            }
            .frame(maxHeight: 400)
        } else {
            failureLabel
        }
    }

    private var failureLabel: some View {
        Label(alt.isEmpty ? "Image failed to load" : alt, systemImage: "photo")
            .foregroundColor(.secondary)
    }
}

private extension RenderedElementView {
    // MARK: - Table

    private func tableView(header: [StyledTableCell], rows: [[StyledTableCell]]) -> some View {
        Grid(alignment: .leading, horizontalSpacing: 0, verticalSpacing: 0) {
            // Header row
            GridRow {
                ForEach(header) { cell in
                    tableCellView(cell)
                }
            }
            .background((header.first?.style.backgroundColor?.color ?? Color.clear).allowsHitTesting(false))

            Divider()

            // Body rows
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                GridRow {
                    ForEach(row) { cell in
                        tableCellView(cell)
                    }
                }
                Divider()
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: block.style.cornerRadius ?? 0)
                .stroke(block.style.borderColor?.color ?? Color.gray.opacity(0.3), lineWidth: block.style.borderWidth ?? 1)
                .allowsHitTesting(false)
        )
    }

    private func tableCellView(_ cell: StyledTableCell) -> some View {
        EditableBlockTextView(
            attributedText: AttributedStringBuilder.build(from: cell.runs),
            onTextChange: { edited in
                let md = MarkdownReconstructor.reconstruct(edited, elementType: .tableCell)
                documentVM.updateTableCellSource(cell, newMarkdown: md)
            },
            onFocus: { textView in
                documentVM.editingBlockId = block.id
                documentVM.activeTextView = textView
                let cellType: MarkupElementType = cell.isHeader ? .tableHeader : .tableCell
                documentVM.editingElementType = cellType
                documentVM.editingStyle = documentVM.stylesheet.resolvedStyle(for: cellType)
            },
            onBlur: { documentVM.finishEditingCell() },
            onSelectionChange: { textView in
                documentVM.updateSelectionSyntaxStack(from: textView)
            },
            onAnchorTap: { anchor in documentVM.scrollToAnchor = anchor }
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(EdgeInsets(
            top: cell.style.paddingTop ?? 4,
            leading: cell.style.paddingLeading ?? 8,
            bottom: cell.style.paddingBottom ?? 4,
            trailing: cell.style.paddingTrailing ?? 8
        ))
        .background(cell.style.backgroundColor?.color ?? Color.clear)
    }

    // MARK: - Background & Hover

    @ViewBuilder
    var backgroundView: some View {
        // Containers handle their own background in childrenView
        if !isContainer, let bgColor = block.style.backgroundColor {
            RoundedRectangle(cornerRadius: block.style.cornerRadius ?? 0)
                .fill(bgColor.color)
        }
    }
}
