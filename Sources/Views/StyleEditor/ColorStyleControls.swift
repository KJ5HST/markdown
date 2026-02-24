import SwiftUI

/// Controls for foreground and background colors
struct ColorStyleControls: View {
    @ObservedObject var viewModel: StyleEditorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Colors")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            // Foreground Color
            HStack {
                Text("Text")
                    .frame(width: 70, alignment: .trailing)
                    .font(.caption)
                ColorPicker("", selection: Binding(
                    get: {
                        viewModel.editingStyle.foregroundColor?.color ?? .primary
                    },
                    set: { newColor in
                        viewModel.updateAndApply { style in
                            style.foregroundColor = CodableColor(color: newColor)
                        }
                    }
                ))
                .labelsHidden()
                Spacer()
            }

            // Background Color
            HStack {
                Text("Background")
                    .frame(width: 70, alignment: .trailing)
                    .font(.caption)
                ColorPicker("", selection: Binding(
                    get: {
                        viewModel.editingStyle.backgroundColor?.color ?? .clear
                    },
                    set: { newColor in
                        viewModel.updateAndApply { style in
                            style.backgroundColor = CodableColor(color: newColor)
                        }
                    }
                ))
                .labelsHidden()

                Button("Clear") {
                    viewModel.updateAndApply { style in
                        style.backgroundColor = nil
                    }
                }
                .font(.caption)

                Spacer()
            }
        }
    }
}
