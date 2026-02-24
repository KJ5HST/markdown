import SwiftUI

/// Main popover view that routes to the appropriate style controls
struct StylePopoverView: View {
    @ObservedObject var viewModel: StyleEditorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text(viewModel.selectedElementType?.displayName ?? "Element")
                    .font(.headline)
                Spacer()
                Button(action: { viewModel.dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    FontStyleControls(viewModel: viewModel)
                    Divider()
                    ColorStyleControls(viewModel: viewModel)
                    Divider()
                    SpacingStyleControls(viewModel: viewModel)
                    Divider()
                    BlockStyleControls(viewModel: viewModel)
                }
                .padding(16)
            }
            .frame(maxHeight: 450)

            Divider()

            // Reset button
            HStack {
                Spacer()
                Button("Reset to Default") {
                    guard let type = viewModel.selectedElementType else { return }
                    viewModel.editingStyle = DefaultStyles.style(for: type)
                    viewModel.applyChanges()
                }
                .font(.caption)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
}
