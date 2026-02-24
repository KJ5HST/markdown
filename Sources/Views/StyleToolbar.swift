import SwiftUI
import AppKit

// MARK: - Popover Color Picker

struct PopoverColorPicker: View {
    let label: String
    @Binding var color: Color
    var icon: String? = nil

    @State private var isOpen = false

    private static let presetColors: [Color] = [
        .black, .white,
        Color(red: 0.3, green: 0.3, blue: 0.3), Color(red: 0.7, green: 0.7, blue: 0.7),
        .red, .orange, .yellow, .green, .blue, .purple,
        Color(red: 0.6, green: 0.2, blue: 0.2), Color(red: 0.8, green: 0.5, blue: 0.2),
        Color(red: 0.7, green: 0.7, blue: 0.2), Color(red: 0.2, green: 0.6, blue: 0.3),
        Color(red: 0.2, green: 0.4, blue: 0.8), Color(red: 0.5, green: 0.2, blue: 0.6),
    ]

    var body: some View {
        Button {
            isOpen.toggle()
        } label: {
            HStack(spacing: 3) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                RoundedRectangle(cornerRadius: 3)
                    .fill(color)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(Color.secondary.opacity(0.4), lineWidth: 0.5)
                    )
                    .frame(width: 16, height: 16)
            }
        }
        .buttonStyle(.plain)
        .popover(isPresented: $isOpen, arrowEdge: .bottom) {
            VStack(spacing: 8) {
                Text(label).font(.caption).foregroundColor(.secondary)
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(22), spacing: 4), count: 6), spacing: 4) {
                    ForEach(Array(Self.presetColors.enumerated()), id: \.offset) { _, preset in
                        Button {
                            color = preset
                            isOpen = false
                        } label: {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(preset)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 3)
                                        .stroke(Color.secondary.opacity(0.3), lineWidth: 0.5)
                                )
                                .frame(width: 22, height: 22)
                        }
                        .buttonStyle(.plain)
                    }
                }
                Divider()
                ColorPicker("Custom:", selection: $color)
                    .font(.caption)
            }
            .padding(10)
            .frame(width: 180)
        }
    }
}

// MARK: - Inline Style Toolbar

struct StyleToolbar: View {
    @EnvironmentObject var documentVM: DocumentViewModel

    private var isDisabled: Bool { documentVM.editingElementType == nil }

    private var fontFamilies: [String] {
        NSFontManager.shared.availableFontFamilies.sorted()
    }

    private var fontSizes: [CGFloat] {
        [8, 9, 10, 11, 12, 13, 14, 16, 18, 20, 24, 28, 32, 36, 40, 48, 56, 64, 72]
    }

    /// Builds the list of available style targets: inline type, block type, parent container
    private var styleTargets: [MarkupElementType] {
        var targets: [MarkupElementType] = []
        if let inlineType = documentVM.activeInlineElementType {
            targets.append(inlineType)
        }
        if let blockType = documentVM.editingElementType {
            targets.append(blockType)
        }
        if let parentType = documentVM.editingParentElementType {
            targets.append(parentType)
        }
        return targets
    }

    @ViewBuilder
    private var styleTargetPicker: some View {
        let targets = styleTargets
        if targets.count > 1 {
            Picker("", selection: Binding(
                get: { documentVM.styleTarget ?? targets.first! },
                set: { documentVM.styleTarget = $0 }
            )) {
                ForEach(targets, id: \.self) { target in
                    Text(target.displayName).tag(target)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(minWidth: 120, maxWidth: 220)
        } else {
            Text(documentVM.editingBlockElementType?.displayName ?? "No Selection")
                .font(.caption)
                .foregroundColor(isDisabled ? .secondary : .primary)
                .frame(minWidth: 60)
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            // Element type label / style target picker
            styleTargetPicker

            Divider().frame(height: 16)

            // Font family picker
            Picker("", selection: Binding(
                get: { documentVM.editingStyle.fontFamily ?? "System Default" },
                set: {
                    documentVM.editingStyle.fontFamily = $0 == "System Default" ? nil : $0
                    documentVM.applyEditingStyle()
                }
            )) {
                Text("System Default").tag("System Default")
                Divider()
                ForEach(fontFamilies, id: \.self) { family in
                    Text(family).tag(family)
                }
            }
            .labelsHidden()
            .frame(maxWidth: 130)
            .disabled(isDisabled)

            // Font size picker
            Picker("", selection: Binding(
                get: { documentVM.editingStyle.fontSize ?? 14 },
                set: { documentVM.editingStyle.fontSize = $0; documentVM.applyEditingStyle() }
            )) {
                ForEach(fontSizes, id: \.self) { size in
                    Text("\(Int(size))").tag(size)
                }
            }
            .labelsHidden()
            .frame(width: 50)
            .disabled(isDisabled)

            // Bold toggle (inline formatting)
            Toggle(isOn: Binding(
                get: { documentVM.selectionSyntaxStack.contains("**") },
                set: { _ in documentVM.toggleInlineFormatting(syntax: "**") }
            )) {
                Text("B").fontWeight(.bold)
            }
            .toggleStyle(.button)
            .font(.caption)
            .disabled(isDisabled)
            .help("Bold")

            // Italic toggle (inline formatting)
            Toggle(isOn: Binding(
                get: { documentVM.selectionSyntaxStack.contains("*") },
                set: { _ in documentVM.toggleInlineFormatting(syntax: "*") }
            )) {
                Text("I").italic()
            }
            .toggleStyle(.button)
            .font(.caption)
            .disabled(isDisabled)
            .help("Italic")

            // Strikethrough toggle (inline formatting)
            Toggle(isOn: Binding(
                get: { documentVM.selectionSyntaxStack.contains("~~") },
                set: { _ in documentVM.toggleInlineFormatting(syntax: "~~") }
            )) {
                Text("S").strikethrough()
            }
            .toggleStyle(.button)
            .font(.caption)
            .disabled(isDisabled)
            .help("Strikethrough")

            // Monospaced toggle (inline formatting)
            Toggle(isOn: Binding(
                get: { documentVM.selectionSyntaxStack.contains("`") },
                set: { _ in documentVM.toggleInlineFormatting(syntax: "`") }
            )) {
                Text("M").font(.system(.caption, design: .monospaced))
            }
            .toggleStyle(.button)
            .disabled(isDisabled)
            .help("Monospaced")

            Divider().frame(height: 16)

            // Text color
            PopoverColorPicker(
                label: "Text",
                color: Binding(
                    get: { documentVM.editingStyle.foregroundColor?.color ?? .primary },
                    set: { documentVM.editingStyle.foregroundColor = CodableColor(color: $0); documentVM.applyEditingStyle() }
                ),
                icon: "textformat"
            )
            .disabled(isDisabled)

            // Block background color
            PopoverColorPicker(
                label: "Background",
                color: Binding(
                    get: { documentVM.editingStyle.backgroundColor?.color ?? .white },
                    set: { documentVM.editingStyle.backgroundColor = CodableColor(color: $0); documentVM.applyEditingStyle() }
                ),
                icon: "highlighter"
            )
            .disabled(isDisabled)

            // Spacing & border popover
            SpacingBorderButton()
                .environmentObject(documentVM)
                .disabled(isDisabled)

            Divider().frame(height: 16)

            // Page background color
            PopoverColorPicker(
                label: "Page",
                color: Binding(
                    get: { documentVM.stylesheet.pageBackgroundColor?.color ?? .white },
                    set: {
                        documentVM.stylesheet.pageBackgroundColor = CodableColor(color: $0)
                        documentVM.rerender()
                    }
                ),
                icon: "doc"
            )

            // Stylesheet menu
            Menu {
                ForEach(StyleSheet.stockStylesheets) { sheet in
                    Button(sheet.name) {
                        documentVM.stylesheet = sheet
                        documentVM.rerender()
                    }
                }
                Divider()
                Button("Manage Stylesheets...") {
                    documentVM.showStylesheetBrowser = true
                }
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: "doc.richtext")
                        .font(.caption2)
                    Text(documentVM.stylesheet.name)
                        .font(.caption)
                }
            }
            .menuStyle(.borderlessButton)
            .fixedSize()

            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(nsColor: .windowBackgroundColor))
        .overlay(alignment: .bottom) { Divider() }
    }
}

// MARK: - Spacing & Border Popover

struct SpacingBorderButton: View {
    @EnvironmentObject var documentVM: DocumentViewModel
    @State private var isOpen = false

    var body: some View {
        Button {
            isOpen.toggle()
        } label: {
            Image(systemName: "slider.horizontal.3")
                .font(.caption)
        }
        .buttonStyle(.plain)
        .help("Spacing & Border")
        .popover(isPresented: $isOpen, arrowEdge: .bottom) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Spacing")
                    .font(.subheadline).fontWeight(.semibold).foregroundColor(.secondary)

                spacingSlider("Top", \.paddingTop)
                spacingSlider("Bottom", \.paddingBottom)
                spacingSlider("Leading", \.paddingLeading)
                spacingSlider("Trailing", \.paddingTrailing)

                HStack {
                    Text("Line Gap").frame(width: 55, alignment: .trailing).font(.caption)
                    Slider(value: Binding(
                        get: { documentVM.editingStyle.lineSpacing ?? 0 },
                        set: { documentVM.editingStyle.lineSpacing = $0; documentVM.applyEditingStyle() }
                    ), in: 0...20, step: 1)
                    Text("\(Int(documentVM.editingStyle.lineSpacing ?? 0))").font(.caption).frame(width: 20)
                }

                Divider()

                Text("Border & Shape")
                    .font(.subheadline).fontWeight(.semibold).foregroundColor(.secondary)

                HStack {
                    Text("Color").frame(width: 55, alignment: .trailing).font(.caption)
                    ColorPicker("", selection: Binding(
                        get: { documentVM.editingStyle.borderColor?.color ?? .clear },
                        set: { documentVM.editingStyle.borderColor = CodableColor(color: $0); documentVM.applyEditingStyle() }
                    )).labelsHidden()
                    Button("Clear") {
                        documentVM.editingStyle.borderColor = nil
                        documentVM.editingStyle.borderWidth = nil
                        documentVM.applyEditingStyle()
                    }.font(.caption)
                    Spacer()
                }

                HStack {
                    Text("Width").frame(width: 55, alignment: .trailing).font(.caption)
                    Slider(value: Binding(
                        get: { documentVM.editingStyle.borderWidth ?? 0 },
                        set: { documentVM.editingStyle.borderWidth = $0; documentVM.applyEditingStyle() }
                    ), in: 0...10, step: 0.5)
                    Text(String(format: "%.1f", documentVM.editingStyle.borderWidth ?? 0)).font(.caption).frame(width: 26)
                }

                HStack {
                    Text("Radius").frame(width: 55, alignment: .trailing).font(.caption)
                    Slider(value: Binding(
                        get: { documentVM.editingStyle.cornerRadius ?? 0 },
                        set: { documentVM.editingStyle.cornerRadius = $0; documentVM.applyEditingStyle() }
                    ), in: 0...24, step: 1)
                    Text("\(Int(documentVM.editingStyle.cornerRadius ?? 0))").font(.caption).frame(width: 20)
                }
            }
            .padding(12)
            .frame(width: 260)
        }
    }

    private func spacingSlider(_ label: String, _ keyPath: WritableKeyPath<ElementStyle, CGFloat?>) -> some View {
        HStack {
            Text(label).frame(width: 55, alignment: .trailing).font(.caption)
            Slider(value: Binding(
                get: { documentVM.editingStyle[keyPath: keyPath] ?? 0 },
                set: { documentVM.editingStyle[keyPath: keyPath] = $0; documentVM.applyEditingStyle() }
            ), in: 0...40, step: 1)
            Text("\(Int(documentVM.editingStyle[keyPath: keyPath] ?? 0))").font(.caption).frame(width: 20)
        }
    }
}
