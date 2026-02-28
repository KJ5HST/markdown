import AppKit
import SwiftUI

/// NSViewRepresentable wrapping an editable NSTextView that displays styled attributed text.
/// Used for editable blocks in the preview pane (paragraphs, headings, code blocks, etc.)
struct EditableBlockTextView: NSViewRepresentable {
    let attributedText: NSAttributedString
    let isCodeBlock: Bool
    let blockId: String?
    let onTextChange: (NSAttributedString) -> Void
    let onFocus: (EditableNSTextView) -> Void
    let onBlur: () -> Void
    let onSelectionChange: ((EditableNSTextView) -> Void)?
    let onNavigateUp: (() -> Void)?
    let onNavigateDown: (() -> Void)?
    let onAnchorTap: ((String) -> Void)?
    let highlightRanges: [(range: NSRange, isCurrent: Bool)]

    init(
        attributedText: NSAttributedString,
        isCodeBlock: Bool = false,
        blockId: String? = nil,
        onTextChange: @escaping (NSAttributedString) -> Void,
        onFocus: @escaping (EditableNSTextView) -> Void = { _ in },
        onBlur: @escaping () -> Void = {},
        onSelectionChange: ((EditableNSTextView) -> Void)? = nil,
        onNavigateUp: (() -> Void)? = nil,
        onNavigateDown: (() -> Void)? = nil,
        onAnchorTap: ((String) -> Void)? = nil,
        highlightRanges: [(range: NSRange, isCurrent: Bool)] = []
    ) {
        self.attributedText = attributedText
        self.isCodeBlock = isCodeBlock
        self.blockId = blockId
        self.onTextChange = onTextChange
        self.onFocus = onFocus
        self.onBlur = onBlur
        self.onSelectionChange = onSelectionChange
        self.onNavigateUp = onNavigateUp
        self.onNavigateDown = onNavigateDown
        self.onAnchorTap = onAnchorTap
        self.highlightRanges = highlightRanges
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onTextChange: onTextChange,
            onFocus: onFocus,
            onBlur: onBlur,
            onSelectionChange: onSelectionChange,
            onNavigateUp: onNavigateUp,
            onNavigateDown: onNavigateDown
        )
    }

    func makeNSView(context: Context) -> EditableNSTextView {
        let textView = EditableNSTextView()
        textView.isCodeBlock = isCodeBlock
        textView.blockId = blockId
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = true
        textView.allowsUndo = true
        textView.drawsBackground = false
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainerInset = .zero
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainer?.widthTracksTextView = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        // Prevent user from changing formatting via menus/keyboard
        textView.usesFontPanel = false
        textView.usesRuler = false
        textView.importsGraphics = false
        textView.delegate = context.coordinator
        textView.onBecomeFirstResponder = { [weak coordinator = context.coordinator, weak textView] in
            guard let textView = textView else { return }
            coordinator?.handleFocusGained(textView: textView)
        }
        textView.onAnchorTap = onAnchorTap
        context.coordinator.isUpdatingFromSwiftUI = true
        textView.textStorage?.setAttributedString(attributedText)
        context.coordinator.isUpdatingFromSwiftUI = false
        // Set typing attributes so new characters match the existing styled text
        applyTypingAttributes(to: textView)
        return textView
    }

    func sizeThatFits(_ proposal: ProposedViewSize, nsView: EditableNSTextView, context: Context) -> CGSize? {
        guard let layoutManager = nsView.layoutManager, let textContainer = nsView.textContainer else {
            return nil
        }
        if let width = proposal.width, width > 0 {
            textContainer.containerSize = NSSize(width: width, height: .greatestFiniteMagnitude)
        }
        layoutManager.ensureLayout(for: textContainer)
        let usedRect = layoutManager.usedRect(for: textContainer)
        return CGSize(width: proposal.width ?? usedRect.width, height: usedRect.height)
    }

    func updateNSView(_ textView: EditableNSTextView, context: Context) {
        let currentText = textView.attributedString().string
        let incomingText = attributedText.string

        if currentText == incomingText {
            // If inline formatting was applied, don't overwrite with stale block-level styles
            if textView.hasInlineFormatChanges {
                applySearchHighlights(to: textView, coordinator: context.coordinator)
                return
            }
            // Same text, possibly new styles — safe to apply (preserves cursor)
            let sel = textView.selectedRange()
            context.coordinator.isUpdatingFromSwiftUI = true
            textView.textStorage?.setAttributedString(attributedText)
            textView.setSelectedRange(sel)
            context.coordinator.isUpdatingFromSwiftUI = false
            applyTypingAttributes(to: textView)
            if let textContainer = textView.textContainer {
                textView.layoutManager?.ensureLayout(for: textContainer)
            }
            textView.invalidateIntrinsicContentSize()
            textView.needsDisplay = true
            context.coordinator.hasPendingEdits = false
        } else if context.coordinator.isEditing {
            // If inline formatting was applied, don't overwrite with stale block-level styles
            if textView.hasInlineFormatChanges {
                applySearchHighlights(to: textView, coordinator: context.coordinator)
                return
            }
            // Text differs while editing — don't overwrite text, but DO apply
            // style attributes (paragraph style, font, color) to the existing text.
            // This ensures style changes (e.g., line spacing) take effect immediately.
            applyStyleAttributes(from: attributedText, to: textView, coordinator: context.coordinator)
            applySearchHighlights(to: textView, coordinator: context.coordinator)
            return
        } else if !context.coordinator.hasPendingEdits {
            // Text differs but no pending edits — genuine external content update
            context.coordinator.isUpdatingFromSwiftUI = true
            textView.textStorage?.setAttributedString(attributedText)
            applyTypingAttributes(to: textView)
            context.coordinator.isUpdatingFromSwiftUI = false
            if let textContainer = textView.textContainer {
                textView.layoutManager?.ensureLayout(for: textContainer)
            }
            textView.invalidateIntrinsicContentSize()
        }
        // If text differs AND hasPendingEdits: skip — stale data, waiting for rerender

        applySearchHighlights(to: textView, coordinator: context.coordinator)
    }

    /// Apply style attributes (paragraph style, font, colors) from the incoming attributed
    /// string to the text view's existing text, without replacing the text content.
    private func applyStyleAttributes(from source: NSAttributedString, to textView: NSTextView, coordinator: Coordinator) {
        guard let textStorage = textView.textStorage, textStorage.length > 0, source.length > 0 else { return }
        // Use attributes from the first character of the incoming string as the canonical style
        let attrs = source.attributes(at: 0, effectiveRange: nil)
        let styleKeys: [NSAttributedString.Key] = [.paragraphStyle, .font, .foregroundColor, .kern]
        let fullRange = NSRange(location: 0, length: textStorage.length)
        coordinator.isUpdatingFromSwiftUI = true
        textStorage.beginEditing()
        for key in styleKeys {
            if let value = attrs[key] {
                textStorage.addAttribute(key, value: value, range: fullRange)
            }
        }
        textStorage.endEditing()
        coordinator.isUpdatingFromSwiftUI = false
        if let textContainer = textView.textContainer {
            textView.layoutManager?.ensureLayout(for: textContainer)
        }
        textView.invalidateIntrinsicContentSize()
        textView.needsDisplay = true
    }

    /// Set typingAttributes from the attributed text at the cursor position (or first character)
    private func applyTypingAttributes(to textView: NSTextView) {
        guard attributedText.length > 0 else { return }
        let index = min(textView.selectedRange().location, attributedText.length - 1)
        let attrs = attributedText.attributes(at: max(index, 0), effectiveRange: nil)
        textView.typingAttributes = attrs
    }

    /// Apply search highlight backgrounds to matching ranges
    private func applySearchHighlights(to textView: NSTextView, coordinator: Coordinator) {
        guard let textStorage = textView.textStorage else { return }
        let fullRange = NSRange(location: 0, length: textStorage.length)

        coordinator.isUpdatingFromSwiftUI = true
        textStorage.beginEditing()
        // Clear existing search highlights
        textStorage.removeAttribute(.backgroundColor, range: fullRange)
        // Apply new highlights
        for highlight in highlightRanges {
            guard highlight.range.location + highlight.range.length <= textStorage.length else { continue }
            let color: NSColor = highlight.isCurrent
                ? NSColor.systemYellow
                : NSColor.systemYellow.withAlphaComponent(0.3)
            textStorage.addAttribute(.backgroundColor, value: color, range: highlight.range)
        }
        textStorage.endEditing()
        coordinator.isUpdatingFromSwiftUI = false
        textView.needsDisplay = true
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        let onTextChange: (NSAttributedString) -> Void
        let onFocus: (EditableNSTextView) -> Void
        let onBlur: () -> Void
        let onSelectionChange: ((EditableNSTextView) -> Void)?
        let onNavigateUp: (() -> Void)?
        let onNavigateDown: (() -> Void)?
        var isEditing = false
        /// True after user has typed — prevents updateNSView from resetting text
        /// before the rerender catches up with fresh data.
        var hasPendingEdits = false
        /// True while updateNSView is programmatically setting attributed text.
        /// Prevents textDidChange from calling onTextChange (which would cause a feedback loop).
        var isUpdatingFromSwiftUI = false

        init(
            onTextChange: @escaping (NSAttributedString) -> Void,
            onFocus: @escaping (EditableNSTextView) -> Void,
            onBlur: @escaping () -> Void,
            onSelectionChange: ((EditableNSTextView) -> Void)?,
            onNavigateUp: (() -> Void)?,
            onNavigateDown: (() -> Void)?
        ) {
            self.onTextChange = onTextChange
            self.onFocus = onFocus
            self.onBlur = onBlur
            self.onSelectionChange = onSelectionChange
            self.onNavigateUp = onNavigateUp
            self.onNavigateDown = onNavigateDown
        }

        /// Called when NSTextView becomes first responder (before any typing)
        func handleFocusGained(textView: EditableNSTextView) {
            isEditing = true
            onFocus(textView)
            onSelectionChange?(textView)
        }

        func textDidBeginEditing(_ notification: Notification) {
            // isEditing already set in handleFocusGained
            isEditing = true
        }

        func textDidEndEditing(_ notification: Notification) {
            isEditing = false
            onBlur()
        }

        func textDidChange(_ notification: Notification) {
            guard !isUpdatingFromSwiftUI else { return }
            guard let textView = notification.object as? NSTextView else { return }
            hasPendingEdits = true
            onTextChange(textView.attributedString())
        }

        /// Update typingAttributes when the cursor moves so new text matches surrounding style
        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? EditableNSTextView else { return }
            let attrString = textView.attributedString()
            guard attrString.length > 0 else { return }
            let pos = textView.selectedRange().location
            let index = min(pos, attrString.length - 1)
            let attrs = attrString.attributes(at: max(index, 0), effectiveRange: nil)
            textView.typingAttributes = attrs
            // Notify about selection changes during user interaction (not programmatic updates)
            if isEditing && !isUpdatingFromSwiftUI {
                onSelectionChange?(textView)
            }
        }

        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            // In non-code blocks, Enter ends editing (commits the block)
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                if let editable = textView as? EditableNSTextView, !editable.isCodeBlock {
                    textView.window?.makeFirstResponder(nil)
                    return true
                }
            }

            // Arrow key navigation between blocks
            if commandSelector == #selector(NSResponder.moveUp(_:)) {
                // Only navigate if cursor (no selection) is on the first visual line
                if textView.selectedRange().length == 0,
                   isOnFirstLine(of: textView),
                   let onNavigateUp = onNavigateUp {
                    onNavigateUp()
                    return true
                }
            }
            if commandSelector == #selector(NSResponder.moveDown(_:)) {
                if textView.selectedRange().length == 0,
                   isOnLastLine(of: textView),
                   let onNavigateDown = onNavigateDown {
                    onNavigateDown()
                    return true
                }
            }

            return false
        }

        // MARK: - Line Detection Helpers

        private func isOnFirstLine(of textView: NSTextView) -> Bool {
            guard let layoutManager = textView.layoutManager,
                  textView.textContainer != nil else { return true }
            let length = textView.textStorage?.length ?? 0
            if length == 0 { return true }
            let cursorIndex = textView.selectedRange().location
            let glyphIndex = layoutManager.glyphIndexForCharacter(at: min(cursorIndex, max(length - 1, 0)))
            var lineRange = NSRange()
            layoutManager.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: &lineRange)
            return lineRange.location == 0
        }

        private func isOnLastLine(of textView: NSTextView) -> Bool {
            guard let layoutManager = textView.layoutManager,
                  textView.textContainer != nil else { return true }
            let length = textView.textStorage?.length ?? 0
            if length == 0 { return true }
            let cursorIndex = textView.selectedRange().location
            // Get line fragment for cursor position
            let cursorGlyphIndex = layoutManager.glyphIndexForCharacter(at: min(cursorIndex, max(length - 1, 0)))
            let cursorLineRect = layoutManager.lineFragmentRect(forGlyphAt: cursorGlyphIndex, effectiveRange: nil)
            // Get line fragment for the last character
            let lastGlyphIndex = layoutManager.glyphIndexForCharacter(at: length - 1)
            let lastLineRect = layoutManager.lineFragmentRect(forGlyphAt: lastGlyphIndex, effectiveRange: nil)
            return cursorLineRect.origin.y == lastLineRect.origin.y
        }
    }
}

/// Custom NSTextView that sizes itself to fit content (no scrolling — parent handles scroll)
/// and manages cursor appearance.
class EditableNSTextView: NSTextView {
    var isCodeBlock = false
    var blockId: String?
    var onBecomeFirstResponder: (() -> Void)?
    /// Called when user clicks a fragment link (e.g. #heading-slug)
    var onAnchorTap: ((String) -> Void)?
    /// Set by toggleInlineFormatting to prevent stale updateNSView from overwriting inline format changes
    var hasInlineFormatChanges = false

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }

    override var acceptsFirstResponder: Bool {
        return true
    }

    override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        if result {
            onBecomeFirstResponder?()
        }
        return result
    }

    override var intrinsicContentSize: NSSize {
        guard let layoutManager = layoutManager, let textContainer = textContainer else {
            return super.intrinsicContentSize
        }
        layoutManager.ensureLayout(for: textContainer)
        let usedRect = layoutManager.usedRect(for: textContainer)
        return NSSize(width: NSView.noIntrinsicMetric, height: usedRect.height + textContainerInset.height * 2)
    }

    override func didChangeText() {
        super.didChangeText()
        invalidateIntrinsicContentSize()
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas where area.owner === self {
            removeTrackingArea(area)
        }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseMoved, .activeInActiveApp, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
    }

    override func mouseMoved(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        if let charIndex = characterIndex(at: point),
           textStorage?.attribute(.linkDestination, at: charIndex, effectiveRange: nil) != nil {
            NSCursor.pointingHand.set()
        } else {
            NSCursor.iBeam.set()
        }
    }

    override func mouseDown(with event: NSEvent) {
        // Check if clicking on a link
        let point = convert(event.locationInWindow, from: nil)
        if let charIndex = characterIndex(at: point),
           let dest = textStorage?.attribute(.linkDestination, at: charIndex, effectiveRange: nil) as? String {
            // Fragment-only link (e.g. #overview) — scroll to heading anchor
            if dest.hasPrefix("#") {
                let anchor = String(dest.dropFirst())
                onAnchorTap?(anchor)
                return
            }
            if let url = URL(string: dest) {
                NSWorkspace.shared.open(url)
                return
            }
        }

        // Explicitly claim first responder so clicks reliably transfer focus
        // between editable blocks embedded in SwiftUI
        window?.makeFirstResponder(self)
        super.mouseDown(with: event)
    }

    /// Returns the character index at a point, or nil if outside text
    private func characterIndex(at point: NSPoint) -> Int? {
        guard let textContainer = textContainer, let layoutManager = layoutManager, let textStorage = textStorage else { return nil }
        let textPoint = NSPoint(x: point.x - textContainerOrigin.x, y: point.y - textContainerOrigin.y)
        let glyphIndex = layoutManager.glyphIndex(for: textPoint, in: textContainer)
        let glyphRect = layoutManager.boundingRect(forGlyphRange: NSRange(location: glyphIndex, length: 1), in: textContainer)
        let adjustedRect = glyphRect.offsetBy(dx: textContainerOrigin.x, dy: textContainerOrigin.y)
        guard adjustedRect.contains(point) else { return nil }
        let charIndex = layoutManager.characterIndexForGlyph(at: glyphIndex)
        guard charIndex < textStorage.length else { return nil }
        return charIndex
    }
}
