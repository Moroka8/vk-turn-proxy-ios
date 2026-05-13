import SwiftUI

struct ProfileListView: View {
    @EnvironmentObject private var profileStore: ProfileStore
    @EnvironmentObject private var runtime: ProxyRuntime
    @State private var editedProfile: ProxyProfile?

    var body: some View {
        NavigationStack {
            List(selection: $profileStore.selectedProfileID) {
                ForEach(profileStore.profiles) { profile in
                    Button {
                        profileStore.selectedProfileID = profile.id
                        editedProfile = profile
                    } label: {
                        ProfileRow(profile: profile, isSelected: profileStore.selectedProfileID == profile.id)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button {
                            profileStore.selectedProfileID = profile.id
                            runtime.start(profile: profile)
                        } label: {
                            Label("Start", systemImage: "play.fill")
                        }
                        .tint(.green)
                    }
                }
                .onDelete(perform: profileStore.delete)
            }
            .navigationTitle("Profiles")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        editedProfile = profileStore.addProfile()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add profile")
                }
            }
            .sheet(item: $editedProfile) { profile in
                ProfileEditorView(profile: profile) { updatedProfile in
                    profileStore.upsert(updatedProfile)
                }
            }
        }
    }
}

private struct ProfileRow: View {
    let profile: ProxyProfile
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isSelected ? .blue : .secondary)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(profile.name)
                    .font(.headline)
                    .lineLimit(1)
                Text("\(profile.linkSummary) · \(profile.peerAddr.isEmpty ? "No peer" : profile.peerAddr)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(profile.listen)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
        .padding(.vertical, 4)
    }
}
