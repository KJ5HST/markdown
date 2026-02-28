import SwiftUI

/// Floating find/replace bar overlaid at top of preview pane
struct FindBarView: View {
    @EnvironmentObject var documentVM: DocumentViewModel
    @FocusState private var isSearchFieldFocused: Bool

    private var fr: FindReplaceState { documentVM.findReplace }

    var body: some View {
        VStack(spacing: 0) {
            // Find row
            HStack(spacing: 6) {
                // Search field
                TextField("Find...", text: Binding(
                    get: { fr.searchQuery },
                    set: { fr.searchQuery = $0 }
                ))
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .frame(minWidth: 140, maxWidth: 220)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(4)
                    .focused($isSearchFieldFocused)
                    .onSubmit { documentVM.navigateToNextMatch() }

                // Match count label
                Text(fr.currentMatchLabel)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(minWidth: 55)

                // Previous match
                Button {
                    documentVM.navigateToPreviousMatch()
                } label: {
                    Image(systemName: "chevron.up")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .disabled(fr.matchCount == 0)
                .help("Previous Match")

                // Next match
                Button {
                    documentVM.navigateToNextMatch()
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .disabled(fr.matchCount == 0)
                .help("Next Match")

                // Case-sensitive toggle
                Toggle(isOn: Binding(
                    get: { fr.isCaseSensitive },
                    set: { fr.isCaseSensitive = $0 }
                )) {
                    Text("Aa")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                }
                .toggleStyle(.button)
                .font(.caption)
                .help("Case Sensitive")

                // Show/hide replace
                Toggle(isOn: Binding(
                    get: { fr.showReplace },
                    set: { fr.showReplace = $0 }
                )) {
                    Image(systemName: "arrow.2.squarepath")
                        .font(.caption)
                }
                .toggleStyle(.button)
                .help("Find and Replace")

                Spacer()

                // Close button
                Button {
                    fr.dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Close (Escape)")
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)

            // Replace row (conditional)
            if fr.showReplace {
                HStack(spacing: 6) {
                    TextField("Replace...", text: Binding(
                        get: { fr.replacementText },
                        set: { fr.replacementText = $0 }
                    ))
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .frame(minWidth: 140, maxWidth: 220)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(4)
                        .onSubmit { documentVM.replaceCurrent() }

                    Button("Replace") {
                        documentVM.replaceCurrent()
                    }
                    .font(.caption)
                    .disabled(fr.matchCount == 0)

                    Button("Replace All") {
                        documentVM.replaceAll()
                    }
                    .font(.caption)
                    .disabled(fr.matchCount == 0)

                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
            }

            Divider()
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear { isSearchFieldFocused = true }
        .onExitCommand { fr.dismiss() }
    }
}
