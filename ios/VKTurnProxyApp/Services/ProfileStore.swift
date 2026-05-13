import Foundation

struct ProfileArchive: Codable {
    var schemaVersion: Int
    var selectedProfileID: UUID?
    var profiles: [ProxyProfile]

    init(schemaVersion: Int = 1, selectedProfileID: UUID?, profiles: [ProxyProfile]) {
        self.schemaVersion = schemaVersion
        self.selectedProfileID = selectedProfileID
        self.profiles = profiles
    }
}

@MainActor
final class ProfileStore: ObservableObject {
    @Published private(set) var profiles: [ProxyProfile] = []
    @Published var selectedProfileID: UUID? {
        didSet { save() }
    }
    @Published var lastError: String?

    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    var selectedProfile: ProxyProfile? {
        guard let selectedProfileID else { return profiles.first }
        return profiles.first { $0.id == selectedProfileID } ?? profiles.first
    }

    init(fileManager: FileManager = .default) {
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        self.fileURL = documents.appendingPathComponent("profiles.json")

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder = encoder
        self.decoder = JSONDecoder()

        load()
    }

    func addProfile() -> ProxyProfile {
        let profile = ProxyProfile(name: nextProfileName())
        profiles.append(profile)
        selectedProfileID = profile.id
        save()
        return profile
    }

    func upsert(_ profile: ProxyProfile) {
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[index] = profile
        } else {
            profiles.append(profile)
        }
        selectedProfileID = profile.id
        save()
    }

    func delete(at offsets: IndexSet) {
        let deletedIDs = offsets.map { profiles[$0].id }
        for index in offsets.sorted(by: >) {
            profiles.remove(at: index)
        }
        if let selectedProfileID, deletedIDs.contains(selectedProfileID) {
            self.selectedProfileID = profiles.first?.id
        }
        save()
    }

    func exportData() throws -> Data {
        try encoder.encode(ProfileArchive(selectedProfileID: selectedProfileID, profiles: profiles))
    }

    func importProfiles(from url: URL) {
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let data = try Data(contentsOf: url)
            try importData(data)
        } catch {
            lastError = error.localizedDescription
        }
    }

    func importData(_ data: Data) throws {
        if let archive = try? decoder.decode(ProfileArchive.self, from: data) {
            merge(archive.profiles)
            selectedProfileID = archive.selectedProfileID ?? profiles.first?.id
            save()
            return
        }
        if let importedProfiles = try? decoder.decode([ProxyProfile].self, from: data) {
            merge(importedProfiles)
            selectedProfileID = importedProfiles.first?.id ?? selectedProfileID
            save()
            return
        }

        let importedProfile = try decoder.decode(ProxyProfile.self, from: data)
        merge([importedProfile])
        selectedProfileID = importedProfile.id
        save()
    }

    private func load() {
        do {
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                profiles = [ProxyProfile()]
                selectedProfileID = profiles.first?.id
                save()
                return
            }
            let archive = try decoder.decode(ProfileArchive.self, from: Data(contentsOf: fileURL))
            profiles = archive.profiles.isEmpty ? [ProxyProfile()] : archive.profiles
            selectedProfileID = archive.selectedProfileID ?? profiles.first?.id
        } catch {
            profiles = [ProxyProfile()]
            selectedProfileID = profiles.first?.id
            lastError = error.localizedDescription
        }
    }

    private func save() {
        do {
            let data = try exportData()
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func merge(_ importedProfiles: [ProxyProfile]) {
        for profile in importedProfiles {
            if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
                profiles[index] = profile
            } else {
                profiles.append(profile)
            }
        }
    }

    private func nextProfileName() -> String {
        let base = "Local proxy"
        var candidate = base
        var suffix = 2
        let existing = Set(profiles.map(\.name))
        while existing.contains(candidate) {
            candidate = "\(base) \(suffix)"
            suffix += 1
        }
        return candidate
    }
}
