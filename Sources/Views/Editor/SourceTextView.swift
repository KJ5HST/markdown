import SwiftUI
import AppKit

/// NSViewRepresentable wrapping NSTextView in NSScrollView for the markdown source editor.
/// Provides scroll fraction tracking and programmatic scroll for scroll sync with the preview.
struct SourceTextView: NSViewRepresentable {
    @Binding var text: String
    var isActivePane: Bool
    @Binding var scrollFraction: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = true
        scrollView.borderType = .noBorder

        let textView = NSTextView()
        textView.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(
            width: 0, height: CGFloat.greatestFiniteMagnitude
        )
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isRichText = false
        textView.usesFindBar = true
        textView.textContainerInset = NSSize(width: 4, height: 4)
        textView.delegate = context.coordinator
        textView.string = text

        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.autoresizingMask = [.width]

        scrollView.documentView = textView

        scrollView.contentView.postsBoundsChangedNotifications = true
        context.coordinator.setupScrollObserver(scrollView: scrollView)

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.parent = self

        guard let textView = scrollView.documentView as? NSTextView else { return }

        // Update text if changed externally (e.g. preview editing updates sourceText)
        if textView.string != text && !context.coordinator.isEditing {
            context.coordinator.isEditing = true
            let ranges = textView.selectedRanges
            textView.string = text
            let length = (textView.string as NSString).length
            let safeRanges = ranges.compactMap { rangeValue -> NSValue? in
                let range = rangeValue.rangeValue
                guard range.location <= length else { return nil }
                let safeLength = min(range.length, length - range.location)
                return NSValue(range: NSRange(location: range.location, length: safeLength))
            }
            if !safeRanges.isEmpty {
                textView.selectedRanges = safeRanges
            }
            context.coordinator.isEditing = false
        }

        // Programmatic scroll: apply fraction from the other pane
        if !isActivePane {
            let fraction = scrollFraction
            if abs(fraction - context.coordinator.lastAppliedFraction) > 0.001 {
                context.coordinator.lastAppliedFraction = fraction
                context.coordinator.isProgrammaticScroll = true

                let documentHeight = scrollView.documentView?.frame.height ?? 0
                let viewportHeight = scrollView.contentView.bounds.height
                let maxScroll = max(0, documentHeight - viewportHeight)
                if maxScroll > 0 {
                    let targetY = fraction * maxScroll
                    scrollView.contentView.setBoundsOrigin(
                        NSPoint(x: 0, y: max(0, min(targetY, maxScroll)))
                    )
                    scrollView.reflectScrolledClipView(scrollView.contentView)
                }

                DispatchQueue.main.async {
                    context.coordinator.isProgrammaticScroll = false
                }
            }
        }
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: SourceTextView
        var isEditing = false
        var isProgrammaticScroll = false
        var lastAppliedFraction: CGFloat = -1
        private var scrollObserver: NSObjectProtocol?

        init(_ parent: SourceTextView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard !isEditing, let textView = notification.object as? NSTextView else { return }
            isEditing = true
            parent.text = textView.string
            isEditing = false
        }

        func setupScrollObserver(scrollView: NSScrollView) {
            scrollObserver = NotificationCenter.default.addObserver(
                forName: NSView.boundsDidChangeNotification,
                object: scrollView.contentView,
                queue: .main
            ) { [weak self, weak scrollView] _ in
                guard let self, let scrollView else { return }
                guard !self.isProgrammaticScroll else { return }
                guard self.parent.isActivePane else { return }

                let bounds = scrollView.contentView.bounds
                let documentHeight = scrollView.documentView?.frame.height ?? 0
                let viewportHeight = bounds.height
                let maxScroll = max(1, documentHeight - viewportHeight)
                let fraction = max(0, min(1, bounds.origin.y / maxScroll))

                self.parent.scrollFraction = fraction
            }
        }

        deinit {
            if let observer = scrollObserver {
                NotificationCenter.default.removeObserver(observer)
            }
        }
    }
}
