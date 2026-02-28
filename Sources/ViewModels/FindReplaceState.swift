import Foundation

/// Holds all find/replace state for the document
@MainActor
class FindReplaceState: ObservableObject {
    @Published var isVisible = false
    @Published var showReplace = false
    @Published var searchQuery = ""
    @Published var replacementText = ""
    @Published var isCaseSensitive = false
    @Published var matches: [Range<String.Index>] = []
    @Published var currentMatchIndex: Int = 0

    var matchCount: Int { matches.count }

    var currentMatchLabel: String {
        guard matchCount > 0 else { return "0 results" }
        return "\(currentMatchIndex + 1) of \(matchCount)"
    }

    func nextMatch() {
        guard matchCount > 0 else { return }
        currentMatchIndex = (currentMatchIndex + 1) % matchCount
    }

    func previousMatch() {
        guard matchCount > 0 else { return }
        currentMatchIndex = (currentMatchIndex - 1 + matchCount) % matchCount
    }

    func dismiss() {
        isVisible = false
        showReplace = false
        searchQuery = ""
        replacementText = ""
        matches = []
        currentMatchIndex = 0
    }
}
