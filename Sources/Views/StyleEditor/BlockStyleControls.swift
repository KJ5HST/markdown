import SwiftUI

/// Controls for border and corner radius
struct BlockStyleControls: View {
    @ObservedObject var viewModel: StyleEditorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Border & Shape")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            // Border Color
            HStack {
                Text("Border")
                    .frame(width: 70, alignment: .trailing)
                    .font(.caption)
                ColorPicker("", selection: Binding(
                    get: {
                        viewModel.editingStyle.borderColor?.color ?? .clear
                    },
                    set: { newColor in
                        viewModel.updateAndApply { style in
                            style.borderColor = CodableColor(color: newColor)
                        }
                    }
                ))
                .labelsHidden()

                Button("Clear") {
                    viewModel.updateAndApply { style in
                        style.borderColor = nil
                        style.borderWidth = nil
                    }
                }
                .font(.caption)

                Spacer()
            }

            // Border Width
            HStack {
                Text("Width")
                    .frame(width: 70, alignment: .trailing)
                    .font(.caption)
                Slider(
                    value: Binding(
                        get: { viewModel.editingStyle.borderWidth ?? 0 },
                        set: { newValue in
                            viewModel.updateAndApply { style in
                                style.borderWidth = newValue
                            }
                        }
                    ),
                    in: 0...10,
                    step: 0.5
                )
                Text(String(format: "%.1f", viewModel.editingStyle.borderWidth ?? 0))
                    .font(.caption)
                    .frame(width: 30)
            }

            // Corner Radius
            HStack {
                Text("Radius")
                    .frame(width: 70, alignment: .trailing)
                    .font(.caption)
                Slider(
                    value: Binding(
                        get: { viewModel.editingStyle.cornerRadius ?? 0 },
                        set: { newValue in
                            viewModel.updateAndApply { style in
                                style.cornerRadius = newValue
                            }
                        }
                    ),
                    in: 0...24,
                    step: 1
                )
                Text("\(Int(viewModel.editingStyle.cornerRadius ?? 0))")
                    .font(.caption)
                    .frame(width: 24)
            }
        }
    }
}
