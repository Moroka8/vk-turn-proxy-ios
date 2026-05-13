import SwiftUI

struct SessionView: View {
    @EnvironmentObject private var profileStore: ProfileStore
    @EnvironmentObject private var runtime: ProxyRuntime

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        StateBadge(state: runtime.state)
                        Spacer()
                        Button {
                            runtime.clearLogs()
                        } label: {
                            Image(systemName: "trash")
                        }
                        .accessibilityLabel("Clear logs")
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(runtime.activeProfile?.name ?? profileStore.selectedProfile?.name ?? "No profile")
                            .font(.title3.weight(.semibold))
                        Text(runtime.activeProfile?.listen ?? profileStore.selectedProfile?.listen ?? "")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 12) {
                        Button {
                            if let profile = profileStore.selectedProfile {
                                runtime.start(profile: profile)
                            }
                        } label: {
                            Label("Start", systemImage: "play.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(runtime.isRunning || profileStore.selectedProfile == nil)

                        Button(role: .destructive) {
                            runtime.stop()
                        } label: {
                            Label("Stop", systemImage: "stop.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(!runtime.isRunning)
                    }
                }
                .padding()
                .background(.regularMaterial)

                LogList(entries: runtime.logs)
            }
            .navigationTitle("Session")
        }
    }
}

private struct LogList: View {
    let entries: [LogEntry]
    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()

    var body: some View {
        ScrollViewReader { proxy in
            List(entries) { entry in
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatter.string(from: entry.date))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                    Text(entry.message)
                        .font(.footnote.monospaced())
                        .textSelection(.enabled)
                }
                .id(entry.id)
            }
            .listStyle(.plain)
            .onChange(of: entries.last?.id) { id in
                guard let id else { return }
                proxy.scrollTo(id, anchor: .bottom)
            }
        }
    }
}
