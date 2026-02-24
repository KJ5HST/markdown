import SwiftUI

/// Full overview of a stylesheet's element styles
struct StylesheetDetailView: View {
    @State var stylesheet: StyleSheet
    var focusName: Bool = false
    let onSave: (StyleSheet) -> Void
    let onApply: (StyleSheet) -> Void
    var onDelete: ((StyleSheet) -> Void)? = nil
    var onNameFocused: (() -> Void)? = nil

    @FocusState private var nameFieldFocused: Bool

    var body: some View {
        Form {
            Section("Info") {
                TextField("Name", text: $stylesheet.name)
                    .focused($nameFieldFocused)
                TextField("Author", text: Binding(
                    get: { stylesheet.author ?? "" },
                    set: { stylesheet.author = $0.isEmpty ? nil : $0 }
                ))
                TextField("Description", text: Binding(
                    get: { stylesheet.description ?? "" },
                    set: { stylesheet.description = $0.isEmpty ? nil : $0 }
                ))
            }

            Section("Customized Elements") {
                if stylesheet.styles.isEmpty {
                    Text("No custom styles defined. Click elements in the preview to customize them.")
                        .foregroundColor(.secondary)
                        .font(.caption)
                } else {
                    ForEach(
                        stylesheet.styles.keys.sorted(by: { $0.rawValue < $1.rawValue }),
                        id: \.self
                    ) { elementType in
                        HStack {
                            Text(elementType.displayName)
                                .font(.body)

                            Spacer()

                            if let style = stylesheet.styles[elementType] {
                                stylePreview(style)
                            }

                            Button(role: .destructive) {
                                stylesheet.removeStyle(for: elementType)
                                onSave(stylesheet)
                            } label: {
                                Image(systemName: "trash")
                                    .font(.caption)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .toolbar {
            ToolbarItem(placement: .destructiveAction) {
                Button(role: .destructive) {
                    onDelete?(stylesheet)
                } label: {
                    Image(systemName: "trash")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Apply") {
                    onApply(stylesheet)
                }
            }
        }
        .onChange(of: stylesheet.name) { _, _ in onSave(stylesheet) }
        .onChange(of: stylesheet.author) { _, _ in onSave(stylesheet) }
        .onChange(of: stylesheet.description) { _, _ in onSave(stylesheet) }
        .onAppear {
            if focusName {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    nameFieldFocused = true
                    onNameFocused?()
                }
            }
        }
        .onChange(of: focusName) { _, newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    nameFieldFocused = true
                    onNameFocused?()
                }
            }
        }
    }

    @ViewBuilder
    private func stylePreview(_ style: ElementStyle) -> some View {
        HStack(spacing: 4) {
            if let size = style.fontSize {
                Text("\(Int(size))pt")
                    .font(.caption2)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(3)
            }
            if let weight = style.fontWeight {
                Text(weight.displayName)
                    .font(.caption2)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(3)
            }
            if let color = style.foregroundColor {
                Circle()
                    .fill(color.color)
                    .frame(width: 12, height: 12)
                    .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 0.5))
            }
        }
    }
}
