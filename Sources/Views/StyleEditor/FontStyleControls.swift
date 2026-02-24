import SwiftUI

/// Controls for font family, size, weight, and italic
struct FontStyleControls: View {
    @ObservedObject var viewModel: StyleEditorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Font")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            // Font Family
            HStack {
                Text("Family")
                    .frame(width: 70, alignment: .trailing)
                    .font(.caption)
                TextField("System Default", text: Binding(
                    get: { viewModel.editingStyle.fontFamily ?? "" },
                    set: { newValue in
                        viewModel.updateAndApply { style in
                            style.fontFamily = newValue.isEmpty ? nil : newValue
                        }
                    }
                ))
                .textFieldStyle(.roundedBorder)
                .font(.caption)
            }

            // Font Size
            HStack {
                Text("Size")
                    .frame(width: 70, alignment: .trailing)
                    .font(.caption)
                Slider(
                    value: Binding(
                        get: { viewModel.editingStyle.fontSize ?? 14 },
                        set: { newValue in
                            viewModel.updateAndApply { style in
                                style.fontSize = newValue
                            }
                        }
                    ),
                    in: 8...72,
                    step: 1
                )
                Text("\(Int(viewModel.editingStyle.fontSize ?? 14))pt")
                    .font(.caption)
                    .frame(width: 32)
            }

            // Font Weight
            HStack {
                Text("Weight")
                    .frame(width: 70, alignment: .trailing)
                    .font(.caption)
                Picker("", selection: Binding(
                    get: { viewModel.editingStyle.fontWeight ?? .regular },
                    set: { newValue in
                        viewModel.updateAndApply { style in
                            style.fontWeight = newValue
                        }
                    }
                )) {
                    ForEach(FontWeight.allCases, id: \.self) { weight in
                        Text(weight.displayName).tag(weight)
                    }
                }
                .labelsHidden()
                .frame(maxWidth: .infinity)
            }

            // Italic & Monospaced toggles
            HStack {
                Text("")
                    .frame(width: 70)
                Toggle("Italic", isOn: Binding(
                    get: { viewModel.editingStyle.isItalic ?? false },
                    set: { newValue in
                        viewModel.updateAndApply { style in
                            style.isItalic = newValue
                        }
                    }
                ))
                .font(.caption)

                Toggle("Monospaced", isOn: Binding(
                    get: { viewModel.editingStyle.isMonospaced ?? false },
                    set: { newValue in
                        viewModel.updateAndApply { style in
                            style.isMonospaced = newValue
                        }
                    }
                ))
                .font(.caption)
            }
        }
    }
}
