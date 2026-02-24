import SwiftUI

/// Controls for padding and line spacing
struct SpacingStyleControls: View {
    @ObservedObject var viewModel: StyleEditorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Spacing")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            spacingSlider(label: "Top", value: \.paddingTop)
            spacingSlider(label: "Bottom", value: \.paddingBottom)
            spacingSlider(label: "Leading", value: \.paddingLeading)
            spacingSlider(label: "Trailing", value: \.paddingTrailing)

            HStack {
                Text("Line Gap")
                    .frame(width: 70, alignment: .trailing)
                    .font(.caption)
                Slider(
                    value: Binding(
                        get: { viewModel.editingStyle.lineSpacing ?? 0 },
                        set: { newValue in
                            viewModel.updateAndApply { style in
                                style.lineSpacing = newValue
                            }
                        }
                    ),
                    in: 0...20,
                    step: 1
                )
                Text("\(Int(viewModel.editingStyle.lineSpacing ?? 0))")
                    .font(.caption)
                    .frame(width: 24)
            }

            HStack {
                Text("Tracking")
                    .frame(width: 70, alignment: .trailing)
                    .font(.caption)
                Slider(
                    value: Binding(
                        get: { viewModel.editingStyle.letterSpacing ?? 0 },
                        set: { newValue in
                            viewModel.updateAndApply { style in
                                style.letterSpacing = newValue
                            }
                        }
                    ),
                    in: -2...10,
                    step: 0.5
                )
                Text(String(format: "%.1f", viewModel.editingStyle.letterSpacing ?? 0))
                    .font(.caption)
                    .frame(width: 30)
            }
        }
    }

    private func spacingSlider(label: String, value keyPath: WritableKeyPath<ElementStyle, CGFloat?>) -> some View {
        HStack {
            Text(label)
                .frame(width: 70, alignment: .trailing)
                .font(.caption)
            Slider(
                value: Binding(
                    get: { viewModel.editingStyle[keyPath: keyPath] ?? 0 },
                    set: { newValue in
                        viewModel.updateAndApply { style in
                            style[keyPath: keyPath] = newValue
                        }
                    }
                ),
                in: 0...40,
                step: 1
            )
            Text("\(Int(viewModel.editingStyle[keyPath: keyPath] ?? 0))")
                .font(.caption)
                .frame(width: 24)
        }
    }
}
