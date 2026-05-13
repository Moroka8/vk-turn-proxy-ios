import SwiftUI

struct ProfileEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: ProxyProfile

    let onSave: (ProxyProfile) -> Void

    init(profile: ProxyProfile, onSave: @escaping (ProxyProfile) -> Void) {
        _draft = State(initialValue: profile)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    TextField("Name", text: $draft.name)
                    TextField("Listen address", text: $draft.listen)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section("Call") {
                    TextField("VK Calls link", text: $draft.vkLink, axis: .vertical)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Yandex Telemost link", text: $draft.yandexLink, axis: .vertical)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Peer address", text: $draft.peerAddr)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section("TURN") {
                    TextField("TURN host override", text: $draft.turnHost)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("TURN port override", text: $draft.turnPort)
                        .keyboardType(.numberPad)
                    Stepper("Streams: \(draft.numStreams)", value: $draft.numStreams, in: 0...64)
                    Toggle("Use UDP transport", isOn: $draft.useUDP)
                    Toggle("Disable DTLS", isOn: $draft.noDTLS)
                }

                Section("Modes") {
                    Toggle("VLESS mode", isOn: $draft.vlessMode)
                    Toggle("VLESS bond", isOn: $draft.vlessBond)
                    Toggle("WRAP mode", isOn: $draft.wrapMode)
                    TextField("WRAP key", text: $draft.wrapKeyHex, axis: .vertical)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Stepper("Streams per credential: \(draft.streamsPerCred)", value: $draft.streamsPerCred, in: 0...64)
                }

                Section("Captcha") {
                    Picker("Solver", selection: $draft.captchaSolver) {
                        ForEach(ProxyProfile.CaptchaSolver.allCases) { solver in
                            Text(solver.rawValue).tag(solver)
                        }
                    }
                    .pickerStyle(.segmented)
                    Toggle("Manual captcha", isOn: $draft.manualCaptcha)
                    Toggle("Debug logging", isOn: $draft.debug)
                }

                Section {
                    TextField("Raw client.Config JSON", text: $draft.rawConfigJSON, axis: .vertical)
                        .lineLimit(4...12)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.system(.footnote, design: .monospaced))
                } header: {
                    Text("Advanced")
                } footer: {
                    Text("When this field is not empty, it is passed directly to the Go binding instead of the form fields.")
                }
            }
            .navigationTitle(draft.name.isEmpty ? "Profile" : draft.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(draft)
                        dismiss()
                    }
                    .disabled(draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
