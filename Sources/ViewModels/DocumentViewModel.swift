import AppKit
import Combine
import PDFKit
import SwiftUI
import UniformTypeIdentifiers

/// Central coordinator: owns source text, stylesheet, and rendered blocks
@MainActor
class DocumentViewModel: ObservableObject {
    @Published var sourceText: String {
        didSet {
            document.sourceText = sourceText
            document.isDirty = true
            if !suppressRerender {
                scheduleRerender()
            }
            if findReplace.isVisible {
                performSearch()
            }
        }
    }
    @Published var styledBlocks: [StyledBlock] = []
    @Published var stylesheet: StyleSheet
    @Published var document: MarkdownDocument
    @Published var showStylesheetBrowser = false
    @Published var editingElementType: MarkupElementType?
    @Published var editingParentElementType: MarkupElementType?
    @Published var styleTarget: MarkupElementType? {
        didSet {
            if let target = styleTarget {
                editingStyle = stylesheet.resolvedStyle(for: target)
            }
        }
    }
    @Published var editingStyle: ElementStyle = .empty
    @Published var renderVersion: Int = 0
    @Published var saveError: String?
    @Published var sourceVisible: Bool = false
    /// Set to a heading anchor slug to trigger programmatic scroll in the preview
    @Published var scrollToAnchor: String?
    let findReplace = FindReplaceState()
    @Published var scrollToBlockId: String?

    @Published var editingBlockId: String? {
        didSet {
            // Cancel any deferred rerender from finishEditing — a new block took focus
            pendingFinishRerenderWorkItem?.cancel()
            pendingFinishRerenderWorkItem = nil
            if let id = editingBlockId,
               let result = findBlockWithParent(id: id, in: styledBlocks) {
                editingElementType = result.block.elementType
                editingParentElementType = result.parent?.elementType
                styleTarget = result.block.elementType
                editingStyle = stylesheet.resolvedStyle(for: result.block.elementType)
            }
        }
    }

    /// The currently active (focused) text view for inline formatting
    weak var activeTextView: EditableNSTextView?
    /// Syntax markers present at the current cursor/selection (for toolbar toggle state)
    @Published var selectionSyntaxStack: Set<String> = []

    /// Element type of the block the cursor is currently in
    var editingBlockElementType: MarkupElementType? {
        guard let id = editingBlockId else { return nil }
        return findBlock(id: id, in: styledBlocks)?.elementType
    }

    /// Inline element type at the cursor (e.g. .inlineCode when on backtick-formatted text)
    var activeInlineElementType: MarkupElementType? {
        if selectionSyntaxStack.contains("`") { return .inlineCode }
        if selectionSyntaxStack.contains("~~") { return .strikethrough }
        if selectionSyntaxStack.contains("**") { return .strong }
        if selectionSyntaxStack.contains("*") { return .emphasis }
        return nil
    }

    private var suppressRerender = false
    private var cancellables = Set<AnyCancellable>()
    private var rerenderWorkItem: DispatchWorkItem?
    /// Deferred rerender scheduled by finishEditing — cancelled if another block takes focus
    private var pendingFinishRerenderWorkItem: DispatchWorkItem?
    /// Live source positions updated after each preview edit (overrides block.sourcePosition)
    private var liveSourcePositions: [String: SourcePosition] = [:]

    init() {
        let doc = MarkdownDocument()
        self.document = doc
        self.sourceText = doc.sourceText
        self.stylesheet = .default
        // Initial render
        let renderer = MarkupRenderer(stylesheet: .default)
        self.styledBlocks = renderer.render(source: doc.sourceText)

        // Subscribe to search query and case sensitivity changes
        findReplace.$searchQuery
            .debounce(for: .milliseconds(150), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.performSearch() }
            .store(in: &cancellables)

        findReplace.$isCaseSensitive
            .sink { [weak self] _ in self?.performSearch() }
            .store(in: &cancellables)

        // Forward findReplace changes so SwiftUI rerenders blocks with highlights
        findReplace.objectWillChange
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    /// Re-render after source text changes (debounced)
    private func scheduleRerender() {
        rerenderWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            Task { @MainActor in
                self?.rerender()
            }
        }
        rerenderWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: workItem)
    }

    /// Immediately re-render with current source and stylesheet
    func rerender() {
        renderVersion += 1
        let renderer = MarkupRenderer(stylesheet: stylesheet, generation: renderVersion)
        styledBlocks = renderer.render(source: sourceText)
        liveSourcePositions.removeAll()
    }

    /// Update the style for a specific element type (called from style editor)
    func updateStyle(_ style: ElementStyle, for elementType: MarkupElementType) {
        stylesheet.setStyle(style, for: elementType)
        rerender() // Immediate, no debounce for style changes
    }

    /// Apply the current editing style
    func applyEditingStyle() {
        guard let elementType = styleTarget ?? editingElementType else { return }
        updateStyle(editingStyle, for: elementType)
    }

    /// Toggle inline formatting syntax (e.g., "**", "*", "`") on the active text view's selection or typing attributes
    func toggleInlineFormatting(syntax: String) {
        guard let textView = activeTextView,
              let textStorage = textView.textStorage else { return }

        let selectedRange = textView.selectedRange()

        if selectedRange.length == 0 {
            // No selection — toggle typing attributes so next typed text carries the formatting
            toggleTypingAttributes(syntax: syntax, textView: textView)
            return
        }

        // Check if ALL runs in the selected range already have this syntax
        var allHaveSyntax = true
        textStorage.enumerateAttributes(in: selectedRange, options: []) { attrs, _, stop in
            let stack = attrs[.markdownSyntax] as? [String] ?? []
            if !stack.contains(syntax) {
                allHaveSyntax = false
                stop.pointee = true
            }
        }

        let removing = allHaveSyntax

        textStorage.beginEditing()
        textStorage.enumerateAttributes(in: selectedRange, options: []) { attrs, range, _ in
            var stack = attrs[.markdownSyntax] as? [String] ?? []
            if removing {
                stack.removeAll { $0 == syntax }
            } else if !stack.contains(syntax) {
                stack.append(syntax)
            }
            if stack.isEmpty {
                textStorage.removeAttribute(.markdownSyntax, range: range)
            } else {
                textStorage.addAttribute(.markdownSyntax, value: stack, range: range)
            }
            // Update visual font trait
            if let currentFont = attrs[.font] as? NSFont,
               let newFont = applyFontTrait(to: currentFont, syntax: syntax, adding: !removing) {
                textStorage.addAttribute(.font, value: newFont, range: range)
            }
            // Handle strikethrough
            if syntax == "~~" {
                if !removing {
                    textStorage.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: range)
                } else {
                    textStorage.removeAttribute(.strikethroughStyle, range: range)
                }
            }
            // Handle inline code foreground color
            if syntax == "`" {
                if !removing, let color = stylesheet.resolvedStyle(for: .inlineCode).foregroundColor {
                    textStorage.addAttribute(.foregroundColor, value: NSColor(color.color), range: range)
                } else if removing, let parentType = editingElementType {
                    let parentColor = stylesheet.resolvedStyle(for: parentType).foregroundColor?.color ?? Color.primary
                    textStorage.addAttribute(.foregroundColor, value: NSColor(parentColor), range: range)
                }
            }
        }
        textStorage.endEditing()

        // Mark that inline formatting was applied (prevents stale updateNSView from overwriting)
        textView.hasInlineFormatChanges = true

        // Trigger text change flow → reconstruction → source update
        textView.didChangeText()

        // Update toolbar state
        if removing {
            selectionSyntaxStack.remove(syntax)
        } else {
            selectionSyntaxStack.insert(syntax)
        }
    }

    /// Update the selection syntax stack from the current state of the active text view
    func updateSelectionSyntaxStack(from textView: EditableNSTextView) {
        let selectedRange = textView.selectedRange()
        let newStack: Set<String>
        if selectedRange.length == 0 {
            let stack = textView.typingAttributes[.markdownSyntax] as? [String] ?? []
            newStack = Set(stack)
        } else {
            guard let textStorage = textView.textStorage else {
                if !selectionSyntaxStack.isEmpty { selectionSyntaxStack = [] }
                return
            }
            var commonSyntax: Set<String>? = nil
            textStorage.enumerateAttributes(in: selectedRange, options: []) { attrs, _, _ in
                let stack = Set(attrs[.markdownSyntax] as? [String] ?? [])
                if let existing = commonSyntax {
                    commonSyntax = existing.intersection(stack)
                } else {
                    commonSyntax = stack
                }
            }
            newStack = commonSyntax ?? []
        }
        // Only publish if actually changed — avoids triggering SwiftUI → updateNSView loop
        if newStack != selectionSyntaxStack {
            selectionSyntaxStack = newStack
        }
    }

    private func toggleTypingAttributes(syntax: String, textView: EditableNSTextView) {
        var typingAttrs = textView.typingAttributes
        var stack = typingAttrs[.markdownSyntax] as? [String] ?? []
        let adding: Bool
        if stack.contains(syntax) {
            stack.removeAll { $0 == syntax }
            adding = false
        } else {
            stack.append(syntax)
            adding = true
        }
        if stack.isEmpty {
            typingAttrs.removeValue(forKey: .markdownSyntax)
        } else {
            typingAttrs[.markdownSyntax] = stack
        }
        if let currentFont = typingAttrs[.font] as? NSFont,
           let newFont = applyFontTrait(to: currentFont, syntax: syntax, adding: adding) {
            typingAttrs[.font] = newFont
        }
        if syntax == "~~" {
            if adding {
                typingAttrs[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
            } else {
                typingAttrs.removeValue(forKey: .strikethroughStyle)
            }
        }
        if syntax == "`" {
            if adding, let color = stylesheet.resolvedStyle(for: .inlineCode).foregroundColor {
                typingAttrs[.foregroundColor] = NSColor(color.color)
            } else if !adding, let parentType = editingElementType {
                let parentColor = stylesheet.resolvedStyle(for: parentType).foregroundColor?.color ?? Color.primary
                typingAttrs[.foregroundColor] = NSColor(parentColor)
            }
        }
        textView.typingAttributes = typingAttrs
        selectionSyntaxStack = Set(stack)
    }

    private func applyFontTrait(to font: NSFont, syntax: String, adding: Bool) -> NSFont? {
        let fm = NSFontManager.shared
        switch syntax {
        case "**":
            return adding
                ? fm.convert(font, toHaveTrait: .boldFontMask)
                : fm.convert(font, toNotHaveTrait: .boldFontMask)
        case "*":
            return adding
                ? fm.convert(font, toHaveTrait: .italicFontMask)
                : fm.convert(font, toNotHaveTrait: .italicFontMask)
        case "`":
            let size = font.pointSize
            if adding {
                let weight: NSFont.Weight = font.fontDescriptor.symbolicTraits.contains(.bold) ? .bold : .regular
                var mono = NSFont.monospacedSystemFont(ofSize: size, weight: weight)
                if font.fontDescriptor.symbolicTraits.contains(.italic) {
                    mono = fm.convert(mono, toHaveTrait: .italicFontMask)
                }
                return mono
            } else {
                let weight: NSFont.Weight = font.fontDescriptor.symbolicTraits.contains(.bold) ? .bold : .regular
                var sys = NSFont.systemFont(ofSize: size, weight: weight)
                if font.fontDescriptor.symbolicTraits.contains(.italic) {
                    sys = fm.convert(sys, toHaveTrait: .italicFontMask)
                }
                return sys
            }
        default:
            return font
        }
    }

    /// Replace the source range of a block with new markdown text.
    /// Called when user edits text in the preview pane.
    func updateBlockSource(_ block: StyledBlock, newMarkdown: String) {
        // Use live position if available, otherwise fall back to render-time position
        let pos = liveSourcePositions[block.id] ?? block.sourcePosition
        guard let pos = pos else {
            debugLog("BAIL: no sourcePosition for block \(block.id)")
            return
        }
        guard let startIdx = sourceIndex(line: pos.startLine, column: pos.startColumn) else {
            debugLog("BAIL: startIdx nil for (\(pos.startLine),\(pos.startColumn))")
            return
        }
        guard let endIdx = sourceIndex(line: pos.endLine, column: pos.endColumn) else {
            debugLog("BAIL: endIdx nil for (\(pos.endLine),\(pos.endColumn)), sourceLen=\(sourceText.count)")
            return
        }

        var updated = sourceText
        updated.replaceSubrange(startIdx..<endIdx, with: newMarkdown)

        // Compute new end position based on start + new content
        var newEndLine = pos.startLine
        var newEndColumn = pos.startColumn
        for ch in newMarkdown {
            if ch == "\n" {
                newEndLine += 1
                newEndColumn = 1
            } else {
                newEndColumn += 1
            }
        }
        liveSourcePositions[block.id] = SourcePosition(
            startLine: pos.startLine, startColumn: pos.startColumn,
            endLine: newEndLine, endColumn: newEndColumn
        )

        // Update sourceText without triggering any re-render while editing.
        // The NSTextView handles its own display; source editor updates via @Published.
        // Full re-render happens on blur (when editingBlockId is cleared).
        suppressRerender = true
        sourceText = updated
        suppressRerender = false
    }

    /// Convert 1-indexed line/column (from swift-markdown) to String.Index
    func sourceIndex(line: Int, column: Int) -> String.Index? {
        var currentLine = 1
        var currentColumn = 1
        for idx in sourceText.indices {
            if currentLine == line && currentColumn == column {
                return idx
            }
            if sourceText[idx] == "\n" {
                currentLine += 1
                currentColumn = 1
            } else {
                currentColumn += 1
            }
        }
        // Handle end-of-file position
        if currentLine == line && currentColumn == column {
            return sourceText.endIndex
        }
        return nil
    }

    /// Replace the source range of a table cell with new markdown text.
    func updateTableCellSource(_ cell: StyledTableCell, newMarkdown: String) {
        guard let pos = cell.sourcePosition else {
            debugLog("BAIL: no sourcePosition for cell \(cell.id)")
            return
        }
        guard let startIdx = sourceIndex(line: pos.startLine, column: pos.startColumn) else {
            debugLog("BAIL: cell startIdx nil for (\(pos.startLine),\(pos.startColumn))")
            return
        }
        guard let endIdx = sourceIndex(line: pos.endLine, column: pos.endColumn) else {
            debugLog("BAIL: cell endIdx nil for (\(pos.endLine),\(pos.endColumn))")
            return
        }

        var updated = sourceText
        updated.replaceSubrange(startIdx..<endIdx, with: newMarkdown)

        suppressRerender = true
        sourceText = updated
        suppressRerender = false
    }

    /// Called when user finishes editing a table cell. Triggers rerender.
    func finishEditingCell() {
        editingBlockId = nil
        liveSourcePositions.removeAll()
        selectionSyntaxStack = []
        activeTextView = nil
        rerender()
    }

    /// Called when user finishes editing a block (blur).
    /// Defers cleanup and rerender so that if another block immediately takes focus,
    /// the rerender is cancelled — preserving the view hierarchy and avoiding
    /// a "No Selection" flash in the toolbar.
    func finishEditing(blockId: String) {
        guard editingBlockId == blockId else { return }
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.pendingFinishRerenderWorkItem = nil
            self.editingBlockId = nil
            self.liveSourcePositions.removeAll()
            self.selectionSyntaxStack = []
            self.activeTextView = nil
            self.rerender()
        }
        pendingFinishRerenderWorkItem = workItem
        DispatchQueue.main.async(execute: workItem)
    }

    /// Reset stylesheet to built-in defaults
    func resetStylesheet() {
        stylesheet = .default
        rerender()
    }

    /// Load a markdown file
    func loadDocument(from url: URL) {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return }
        document = MarkdownDocument(sourceText: content, fileURL: url)
        suppressRerender = true
        sourceText = content
        suppressRerender = false
        document.isDirty = false
        rerender()
    }

    // MARK: - Find & Replace

    /// Search sourceText for all occurrences of the query
    func performSearch() {
        let query = findReplace.searchQuery
        guard !query.isEmpty else {
            findReplace.matches = []
            findReplace.currentMatchIndex = 0
            return
        }

        let options: String.CompareOptions = findReplace.isCaseSensitive ? [] : [.caseInsensitive]
        var results: [Range<String.Index>] = []
        var searchStart = sourceText.startIndex

        while searchStart < sourceText.endIndex,
              let range = sourceText.range(of: query, options: options, range: searchStart..<sourceText.endIndex) {
            results.append(range)
            searchStart = range.upperBound
        }

        findReplace.matches = results
        if findReplace.currentMatchIndex >= results.count {
            findReplace.currentMatchIndex = max(results.count - 1, 0)
        }
    }

    /// Replace the match at the current index
    func replaceCurrent() {
        guard findReplace.currentMatchIndex < findReplace.matches.count else { return }
        let range = findReplace.matches[findReplace.currentMatchIndex]
        sourceText.replaceSubrange(range, with: findReplace.replacementText)
    }

    /// Replace all matches (in reverse order to preserve indices)
    func replaceAll() {
        guard !findReplace.matches.isEmpty else { return }
        var text = sourceText
        for range in findReplace.matches.reversed() {
            text.replaceSubrange(range, with: findReplace.replacementText)
        }
        sourceText = text
    }

    /// Navigate to the next match and scroll to it
    func navigateToNextMatch() {
        findReplace.nextMatch()
        scrollToCurrentMatch()
    }

    /// Navigate to the previous match and scroll to it
    func navigateToPreviousMatch() {
        findReplace.previousMatch()
        scrollToCurrentMatch()
    }

    /// Scroll the preview to the block containing the current match
    func scrollToCurrentMatch() {
        guard findReplace.currentMatchIndex < findReplace.matches.count else { return }
        let matchRange = findReplace.matches[findReplace.currentMatchIndex]
        let matchOffset = sourceText.distance(from: sourceText.startIndex, to: matchRange.lowerBound)

        // Convert offset to line number (1-indexed)
        var line = 1
        var count = 0
        for ch in sourceText {
            if count >= matchOffset { break }
            if ch == "\n" { line += 1 }
            count += 1
        }

        // Find the block whose source position contains this line
        if let blockId = findBlockContainingLine(line, in: styledBlocks) {
            scrollToBlockId = blockId
        }
    }

    /// Recursively find the block containing the given source line
    private func findBlockContainingLine(_ line: Int, in blocks: [StyledBlock]) -> String? {
        for block in blocks {
            if let pos = block.sourcePosition,
               line >= pos.startLine && line <= pos.endLine {
                // Check children for a more specific match
                switch block.content {
                case .children(let children), .listItem(_, let children):
                    if let childId = findBlockContainingLine(line, in: children) {
                        return childId
                    }
                default:
                    break
                }
                return block.id
            }
        }
        return nil
    }

    /// Compute highlight ranges for a block's rendered text based on the current search query.
    /// Returns an array of (NSRange, isCurrent) tuples for highlighting in EditableBlockTextView.
    func highlightRangesInRenderedText(for block: StyledBlock) -> [(range: NSRange, isCurrent: Bool)] {
        let query = findReplace.searchQuery
        guard findReplace.isVisible, !query.isEmpty else { return [] }

        // Extract the block's plain text from its content
        let blockText = plainText(for: block)
        guard !blockText.isEmpty else { return [] }

        let options: String.CompareOptions = findReplace.isCaseSensitive ? [] : [.caseInsensitive]
        var highlights: [(range: NSRange, isCurrent: Bool)] = []
        var searchStart = blockText.startIndex

        // Track which global match this block's local matches correspond to
        let blockSourceRange = sourceRangeForBlock(block)

        while searchStart < blockText.endIndex,
              let range = blockText.range(of: query, options: options, range: searchStart..<blockText.endIndex) {
            let nsRange = NSRange(range, in: blockText)

            // Determine if this local match is the current global match
            let isCurrent = isCurrentGlobalMatch(localRange: range, blockText: blockText, blockSourceRange: blockSourceRange)

            highlights.append((range: nsRange, isCurrent: isCurrent))
            searchStart = range.upperBound
        }

        return highlights
    }

    /// Extract plain text from a block's content
    private func plainText(for block: StyledBlock) -> String {
        switch block.content {
        case .inline(let runs):
            return runs.map(\.text).joined()
        case .code(_, let text):
            return text
        default:
            return ""
        }
    }

    /// Get the source text range for a block
    private func sourceRangeForBlock(_ block: StyledBlock) -> Range<String.Index>? {
        guard let pos = block.sourcePosition,
              let start = sourceIndex(line: pos.startLine, column: pos.startColumn),
              let end = sourceIndex(line: pos.endLine, column: pos.endColumn) else {
            return nil
        }
        return start..<end
    }

    /// Check if a local match in a block's rendered text corresponds to the current global match
    private func isCurrentGlobalMatch(localRange: Range<String.Index>, blockText: String, blockSourceRange: Range<String.Index>?) -> Bool {
        guard findReplace.currentMatchIndex < findReplace.matches.count,
              let blockSourceRange = blockSourceRange else { return false }

        let currentGlobalMatch = findReplace.matches[findReplace.currentMatchIndex]

        // Check if the current global match falls within this block's source range
        guard currentGlobalMatch.lowerBound >= blockSourceRange.lowerBound,
              currentGlobalMatch.upperBound <= blockSourceRange.upperBound else {
            return false
        }

        // The source text includes markdown syntax, so offsets won't match exactly.
        // Instead, count which occurrence of the query this is in both source and rendered text.
        let query = findReplace.searchQuery
        let options: String.CompareOptions = findReplace.isCaseSensitive ? [] : [.caseInsensitive]

        // Count which occurrence this local match is
        var localOccurrence = 0
        var searchPos = blockText.startIndex
        while searchPos < localRange.lowerBound,
              let found = blockText.range(of: query, options: options, range: searchPos..<blockText.endIndex) {
            if found.lowerBound < localRange.lowerBound {
                localOccurrence += 1
                searchPos = found.upperBound
            } else {
                break
            }
        }

        // Count which occurrence the global match is within the block's source
        let blockSource = String(sourceText[blockSourceRange])
        var globalOccurrence = 0
        searchPos = blockSource.startIndex
        let globalMatchInBlockOffset = sourceText.distance(from: blockSourceRange.lowerBound, to: currentGlobalMatch.lowerBound)
        let globalMatchInBlockStart = blockSource.index(blockSource.startIndex, offsetBy: globalMatchInBlockOffset)
        while searchPos < globalMatchInBlockStart,
              let found = blockSource.range(of: query, options: options, range: searchPos..<blockSource.endIndex) {
            if found.lowerBound < globalMatchInBlockStart {
                globalOccurrence += 1
                searchPos = found.upperBound
            } else {
                break
            }
        }

        return localOccurrence == globalOccurrence
    }

    // MARK: - Anchor Navigation

    /// Look up the block ID for a given heading anchor slug
    func blockId(forAnchor anchor: String) -> String? {
        return findBlockByAnchor(anchor, in: styledBlocks)
    }

    private func findBlockByAnchor(_ anchor: String, in blocks: [StyledBlock]) -> String? {
        for block in blocks {
            if block.anchor == anchor { return block.id }
            switch block.content {
            case .children(let children), .listItem(_, let children):
                if let found = findBlockByAnchor(anchor, in: children) { return found }
            default:
                break
            }
        }
        return nil
    }

    // MARK: - Block Navigation

    /// Returns a flat list of all editable block IDs in document order
    func flatEditableBlockIds() -> [String] {
        var ids: [String] = []
        collectEditableIds(from: styledBlocks, into: &ids)
        return ids
    }

    private func collectEditableIds(from blocks: [StyledBlock], into ids: inout [String]) {
        for block in blocks {
            switch block.content {
            case .inline, .code:
                ids.append(block.id)
            case .children(let children):
                collectEditableIds(from: children, into: &ids)
            case .listItem(_, let children):
                collectEditableIds(from: children, into: &ids)
            case .thematicBreak, .image, .table:
                break
            }
        }
    }

    /// Navigate to the previous editable block from the given block ID
    func navigateToPreviousBlock(from blockId: String) {
        let ids = flatEditableBlockIds()
        guard let index = ids.firstIndex(of: blockId), index > 0 else { return }
        focusBlock(id: ids[index - 1], atEnd: true)
    }

    /// Navigate to the next editable block from the given block ID
    func navigateToNextBlock(from blockId: String) {
        let ids = flatEditableBlockIds()
        guard let index = ids.firstIndex(of: blockId), index < ids.count - 1 else { return }
        focusBlock(id: ids[index + 1], atEnd: false)
    }

    /// Focus an EditableNSTextView by its blockId, placing the cursor at the start or end
    func focusBlock(id: String, atEnd: Bool) {
        guard let window = activeTextView?.window,
              let contentView = window.contentView else { return }
        guard let targetView = findTextView(blockId: id, in: contentView) else { return }
        // Pre-set editingBlockId so the old block's finishEditing guard fails
        editingBlockId = id
        window.makeFirstResponder(targetView)
        let length = targetView.textStorage?.length ?? 0
        let position = atEnd ? length : 0
        targetView.setSelectedRange(NSRange(location: position, length: 0))
    }

    /// Recursively find an EditableNSTextView with matching blockId in the view hierarchy
    private func findTextView(blockId: String, in view: NSView) -> EditableNSTextView? {
        if let textView = view as? EditableNSTextView, textView.blockId == blockId {
            return textView
        }
        for subview in view.subviews {
            if let found = findTextView(blockId: blockId, in: subview) {
                return found
            }
        }
        return nil
    }

    /// Recursively find a block by ID (blocks can be nested in children/listItems)
    private func findBlock(id: String, in blocks: [StyledBlock]) -> StyledBlock? {
        for block in blocks {
            if block.id == id { return block }
            switch block.content {
            case .children(let children), .listItem(_, let children):
                if let found = findBlock(id: id, in: children) { return found }
            default:
                break
            }
        }
        return nil
    }

    /// Recursively find a block by ID, returning the block and its nearest parent container
    private func findBlockWithParent(id: String, in blocks: [StyledBlock], parent: StyledBlock? = nil) -> (block: StyledBlock, parent: StyledBlock?)? {
        for block in blocks {
            if block.id == id { return (block, parent) }
            switch block.content {
            case .children(let children):
                if let found = findBlockWithParent(id: id, in: children, parent: block) { return found }
            case .listItem(_, let children):
                if let found = findBlockWithParent(id: id, in: children, parent: block) { return found }
            default:
                break
            }
        }
        return nil
    }

    // MARK: - PDF Export & Print

    private let exportMargin: CGFloat = 54   // 3/4 inch
    private let pageSize = NSSize(width: 612, height: 792) // US Letter

    /// Export the rendered preview as a multi-page PDF file
    func exportPDF() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = pdfFileName
        guard panel.runModal() == .OK, let url = panel.url else { return }

        let pdfDocument = buildPDFDocument()
        pdfDocument.write(to: url)
    }

    /// Print the rendered preview via the system print dialog
    func printDocument() {
        let pdfDocument = buildPDFDocument()
        let printView = PDFPrintView(pdfDocument: pdfDocument, pdfPageSize: pageSize)

        let printInfo = NSPrintInfo.shared.copy() as! NSPrintInfo
        printInfo.paperSize = pageSize
        // Margins are baked into each page, so print-level margins are zero
        printInfo.topMargin = 0
        printInfo.bottomMargin = 0
        printInfo.leftMargin = 0
        printInfo.rightMargin = 0
        printInfo.isHorizontallyCentered = false
        printInfo.isVerticallyCentered = false

        let printOp = NSPrintOperation(view: printView, printInfo: printInfo)
        printOp.run()
    }

    /// Render each page via dataWithPDF (captures all SwiftUI content) and combine with PDFKit
    private func buildPDFDocument() -> PDFDocument {
        let contentWidth = pageSize.width - 2 * exportMargin
        let contentHeight = pageSize.height - 2 * exportMargin
        let pages = paginateBlocks(contentWidth: contentWidth, pageContentHeight: contentHeight)

        // Reusable off-screen window for rendering pages
        let renderWindow = NSWindow(
            contentRect: NSRect(origin: .init(x: -10000, y: -10000), size: pageSize),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        renderWindow.appearance = NSAppearance(named: .aqua)

        let pdfDocument = PDFDocument()

        for (i, pageBlocks) in pages.enumerated() {
            let pageView = PrintablePageView(
                blocks: pageBlocks,
                stylesheet: stylesheet,
                pageSize: CGSize(width: pageSize.width, height: pageSize.height),
                margin: exportMargin,
                documentURL: document.fileURL
            )
            let hostingView = NSHostingView(rootView: pageView)
            hostingView.frame = NSRect(origin: .zero, size: pageSize)
            renderWindow.contentView = hostingView
            hostingView.layoutSubtreeIfNeeded()

            let pdfData = hostingView.dataWithPDF(inside: hostingView.bounds)
            if let pagePDF = PDFDocument(data: pdfData), let page = pagePDF.page(at: 0) {
                pdfDocument.insert(page, at: i)
            }
        }

        return pdfDocument
    }

    /// Assign blocks to pages so no block is split across a page boundary.
    /// Measures blocks inside a real window so NSTextView representables lay out accurately.
    private func paginateBlocks(contentWidth: CGFloat, pageContentHeight: CGFloat) -> [[StyledBlock]] {
        // Reusable off-screen window for accurate measurement of NSViewRepresentable content
        let measureWindow = NSWindow(
            contentRect: NSRect(origin: .init(x: -20000, y: -20000),
                                size: NSSize(width: contentWidth, height: 10000)),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        measureWindow.appearance = NSAppearance(named: .aqua)

        var pages: [[StyledBlock]] = [[]]
        var remainingHeight = pageContentHeight

        let blocks = styledBlocks
        var heights: [CGFloat] = []
        for block in blocks {
            heights.append(measureBlockHeight(block, contentWidth: contentWidth, window: measureWindow))
        }

        for (i, block) in blocks.enumerated() {
            let blockHeight = heights[i]

            if blockHeight > remainingHeight && !pages[pages.count - 1].isEmpty {
                // Block won't fit — start a new page
                pages.append([block])
                remainingHeight = pageContentHeight - blockHeight
            } else {
                pages[pages.count - 1].append(block)
                remainingHeight -= blockHeight
            }

            // If a heading just landed as the last item on this page, push it to the next page
            if block.elementType.isHeading {
                let nextHeight = (i + 1 < blocks.count) ? heights[i + 1] : 0
                if nextHeight > remainingHeight {
                    // Remove heading from current page, start a new page with it
                    pages[pages.count - 1].removeLast()
                    pages.append([block])
                    remainingHeight = pageContentHeight - blockHeight
                }
            }
        }

        return pages
    }

    /// Measure the rendered height of a single block at the given width,
    /// using a real off-screen window so the NSTextView inside sizeThatFits properly.
    private func measureBlockHeight(_ block: StyledBlock, contentWidth: CGFloat, window: NSWindow) -> CGFloat {
        let view = StaticRenderedElementView(block: block, stylesheet: stylesheet, documentURL: document.fileURL)
            .frame(width: contentWidth)
        let hostingView = NSHostingView(rootView: view)
        hostingView.frame = NSRect(x: 0, y: 0, width: contentWidth, height: 10000)
        window.contentView = hostingView
        hostingView.layoutSubtreeIfNeeded()
        // ceil prevents sub-pixel accumulation from overflowing the page
        return ceil(hostingView.fittingSize.height)
    }

    private var pdfFileName: String {
        let name = document.displayName
        if name.lowercased().hasSuffix(".md") {
            return String(name.dropLast(3)) + ".pdf"
        }
        return name + ".pdf"
    }

    /// Reset to a fresh untitled document
    func newDocument() {
        document = MarkdownDocument()
        suppressRerender = true
        sourceText = document.sourceText
        suppressRerender = false
        document.isDirty = false
        editingBlockId = nil
        liveSourcePositions.removeAll()
        selectionSyntaxStack = []
        activeTextView = nil
        rerender()
    }

    /// Reload the current file from disk, discarding unsaved changes
    func revertToSaved() {
        guard let url = document.fileURL else { return }
        loadDocument(from: url)
    }

    /// Save current document
    func saveDocument() {
        if let url = document.fileURL {
            do {
                try sourceText.write(to: url, atomically: true, encoding: .utf8)
                document.isDirty = false
            } catch {
                saveError = error.localizedDescription
            }
        } else {
            DocumentStorage.saveMarkdownFile(source: sourceText) { [weak self] url in
                if let url = url {
                    self?.document.fileURL = url
                    self?.document.isDirty = false
                }
            }
        }
    }
}

// MARK: - PDF Print View

/// Draws pre-rendered PDF pages via CoreGraphics so NSPrintOperation captures all content
/// (SwiftUI drawing primitives like Rectangle, Text, stroke don't render through NSPrintOperation's
/// normal NSView draw path, but they ARE captured by dataWithPDF — so we render to PDF first,
/// then draw the PDF pages here).
private class PDFPrintView: NSView {
    let pdfDocument: PDFDocument
    let pdfPageSize: NSSize

    init(pdfDocument: PDFDocument, pdfPageSize: NSSize) {
        self.pdfDocument = pdfDocument
        self.pdfPageSize = pdfPageSize
        let totalHeight = pdfPageSize.height * CGFloat(pdfDocument.pageCount)
        super.init(frame: NSRect(origin: .zero, size: NSSize(width: pdfPageSize.width, height: totalHeight)))
    }

    required init?(coder: NSCoder) { fatalError() }

    override var isFlipped: Bool { true }

    override func knowsPageRange(_ range: NSRangePointer) -> Bool {
        range.pointee = NSRange(location: 1, length: pdfDocument.pageCount)
        return true
    }

    override func rectForPage(_ page: Int) -> NSRect {
        let y = CGFloat(page - 1) * pdfPageSize.height
        return NSRect(x: 0, y: y, width: pdfPageSize.width, height: pdfPageSize.height)
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        for i in 0..<pdfDocument.pageCount {
            let pageY = CGFloat(i) * pdfPageSize.height
            let pageRect = NSRect(x: 0, y: pageY, width: pdfPageSize.width, height: pdfPageSize.height)

            guard pageRect.intersects(dirtyRect),
                  let page = pdfDocument.page(at: i)?.pageRef else { continue }

            context.saveGState()
            // Flip from our flipped coords back to PDF coords (origin bottom-left, y up)
            context.translateBy(x: 0, y: pageY + pdfPageSize.height)
            context.scaleBy(x: 1, y: -1)
            context.drawPDFPage(page)
            context.restoreGState()
        }
    }
}
