import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var profileStore: ProfileStore
    @State private var isImporting = false
    @State private var isExporting = false
    @State private var exportDocument = ProfileExportDocument()

    var body: some View {
        NavigationStack {
            Form {
                Section("Profiles") {
                    Button {
                        prepareExport()
                    } label: {
                        Label("Export JSON", systemImage: "square.and.arrow.up")
                    }

                    Button {
                        isImporting = true
                    } label: {
                        Label("Import JSON", systemImage: "square.and.arrow.down")
                    }
                }

                if let lastError = profileStore.lastError {
                    Section("Last error") {
                        Text(lastError)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Settings")
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                guard case let .success(urls) = result, let url = urls.first else { return }
                profileStore.importProfiles(from: url)
            }
            .fileExporter(
                isPresented: $isExporting,
                document: exportDocument,
                contentType: .json,
                defaultFilename: "vk-turn-proxy-profiles"
            ) { _ in }
        }
    }

    private func prepareExport() {
        do {
            exportDocument = ProfileExportDocument(data: try profileStore.exportData())
            isExporting = true
        } catch {
            profileStore.lastError = error.localizedDescription
        }
    }
}
