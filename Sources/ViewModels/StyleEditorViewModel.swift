import SwiftUI

/// Manages the state for the inline style editor popover
@MainActor
class StyleEditorViewModel: ObservableObject {
    @Published var selectedElementType: MarkupElementType?
    @Published var isPopoverPresented = false
    @Published var editingStyle: ElementStyle = .empty

    weak var documentVM: DocumentViewModel?

    func select(elementType: MarkupElementType, in documentVM: DocumentViewModel) {
        self.documentVM = documentVM
        self.selectedElementType = elementType
        self.editingStyle = documentVM.stylesheet.resolvedStyle(for: elementType)
        self.isPopoverPresented = true
    }

    func dismiss() {
        isPopoverPresented = false
        selectedElementType = nil
    }

    /// Apply the current editing style to the document stylesheet
    func applyChanges() {
        guard let elementType = selectedElementType else { return }
        documentVM?.updateStyle(editingStyle, for: elementType)
    }

    /// Update a single property and immediately apply
    func updateAndApply(_ update: (inout ElementStyle) -> Void) {
        update(&editingStyle)
        applyChanges()
    }
}
