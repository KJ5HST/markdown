import SwiftUI

/// List and manage saved stylesheets
struct StylesheetBrowserView: View {
    @EnvironmentObject var documentVM: DocumentViewModel
    @State private var stylesheets: [StyleSheet] = []
    @State private var selectedStylesheet: StyleSheet?
    @State private var focusNameFieldFor: UUID?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedStylesheet) {
                ForEach(stylesheets) { sheet in
                    VStack(alignment: .leading) {
                        Text(sheet.name)
                            .font(.headline)
                        if let desc = sheet.description {
                            Text(desc)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Text("Modified: \(sheet.modifiedAt.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .tag(sheet)
                    .padding(.vertical, 2)
                    .contextMenu {
                        Button("Delete", role: .destructive) {
                            deleteStylesheet(sheet)
                        }
                    }
                }
            }
            .navigationTitle("Stylesheets")
            .frame(minWidth: 200)
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button(action: deleteSelected) {
                        Image(systemName: "minus")
                    }
                    .disabled(selectedStylesheet == nil)
                    Button(action: createNewStylesheet) {
                        Image(systemName: "plus")
                    }
                }
            }
        } detail: {
            if let selected = selectedStylesheet {
                StylesheetDetailView(
                    stylesheet: selected,
                    focusName: focusNameFieldFor == selected.id
                ) { updated in
                    StylesheetStorage.shared.save(updated)
                    loadStylesheets()
                } onApply: { sheet in
                    documentVM.stylesheet = sheet
                    dismiss()
                } onDelete: { sheet in
                    deleteStylesheet(sheet)
                } onNameFocused: {
                    focusNameFieldFor = nil
                }
            } else {
                Text("Select a stylesheet")
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            loadStylesheets()
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save Current") {
                    saveCurrentStylesheet()
                }
            }
        }
    }

    private func loadStylesheets() {
        stylesheets = StylesheetStorage.shared.loadAll()
    }

    private func selectAndFocus(_ sheet: StyleSheet) {
        selectedStylesheet = sheet
        focusNameFieldFor = sheet.id
    }

    private func saveCurrentStylesheet() {
        var current = documentVM.stylesheet
        current.modifiedAt = Date()
        StylesheetStorage.shared.save(current)
        loadStylesheets()
        if let saved = stylesheets.first(where: { $0.id == current.id }) {
            selectAndFocus(saved)
        }
    }

    private func deleteStylesheet(_ sheet: StyleSheet) {
        StylesheetStorage.shared.delete(sheet)
        if selectedStylesheet?.id == sheet.id {
            selectedStylesheet = nil
        }
        loadStylesheets()
    }

    private func deleteSelected() {
        guard let selected = selectedStylesheet else { return }
        deleteStylesheet(selected)
    }

    private func createNewStylesheet() {
        let newSheet = StyleSheet(name: "New Stylesheet")
        StylesheetStorage.shared.save(newSheet)
        loadStylesheets()
        if let saved = stylesheets.first(where: { $0.id == newSheet.id }) {
            selectAndFocus(saved)
        }
    }
}
