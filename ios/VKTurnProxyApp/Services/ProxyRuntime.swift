import Foundation

#if canImport(Mobile)
import Mobile
#endif

enum ProxyState: Equatable {
    case stopped
    case connecting
    case running
    case error(String)

    var title: String {
        switch self {
        case .stopped:
            return "Stopped"
        case .connecting:
            return "Connecting"
        case .running:
            return "Running"
        case .error:
            return "Error"
        }
    }
}

struct LogEntry: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let message: String
}

@MainActor
final class ProxyRuntime: ObservableObject {
    @Published private(set) var state: ProxyState = .stopped
    @Published private(set) var activeProfile: ProxyProfile?
    @Published private(set) var logs: [LogEntry] = []
    @Published private(set) var lastError: String?

    private let client = MobileClientAdapter()

    var isRunning: Bool {
        if case .running = state { return true }
        if case .connecting = state { return true }
        return client.isRunning()
    }

    func start(profile: ProxyProfile) {
        guard !isRunning else { return }
        guard profile.canStart else {
            state = .error("Profile needs peer address and exactly one call link.")
            lastError = "Profile needs peer address and exactly one call link."
            return
        }

        do {
            let configJSON = try profile.configJSONString()

            activeProfile = profile
            lastError = nil
            state = .connecting
            appendLog("Starting \(profile.name) on \(profile.listen)")

            let error = client.start(configJSON: configJSON, sink: self)
            if !error.isEmpty {
                state = .error(error)
                lastError = error
                appendLog(error)
                activeProfile = nil
            }
        } catch {
            state = .error(error.localizedDescription)
            lastError = error.localizedDescription
            appendLog(error.localizedDescription)
            activeProfile = nil
        }
    }

    func stop() {
        guard isRunning else { return }
        appendLog("Stopping client")
        client.stop()
    }

    func clearLogs() {
        logs.removeAll()
    }

    fileprivate func receiveLog(_ message: String) {
        appendLog(message)
        let lowercased = message.lowercased()
        if lowercased.contains("listening on") || lowercased.contains("listener on") {
            state = .running
        }
    }

    fileprivate func receiveStatus(_ status: String) {
        if status == "CONNECTING" {
            state = .connecting
            return
        }
        if status == "STOPPED" {
            state = .stopped
            activeProfile = nil
            appendLog("Stopped")
            return
        }
        if status.hasPrefix("ERROR:") {
            let message = String(status.dropFirst("ERROR:".count))
            state = .error(message)
            lastError = message
            activeProfile = nil
            appendLog(message)
            return
        }
        appendLog("Status: \(status)")
    }

    private func appendLog(_ message: String) {
        logs.append(LogEntry(date: Date(), message: message))
        if logs.count > 500 {
            logs.removeFirst(logs.count - 500)
        }
    }
}

private final class MobileClientAdapter {
#if canImport(Mobile)
    private let client: MobileIosClient?
    private var callback: MobileCallback?

    init() {
        client = MobileIosNewClient()
    }

    func start(configJSON: String, sink: ProxyRuntime) -> String {
        guard let client else {
            return "Mobile client is unavailable."
        }
        let callback = MobileCallback(sink: sink)
        self.callback = callback
        return client.start(configJSON, callback: callback) ?? ""
    }

    func stop() {
        client?.stop()
    }

    func isRunning() -> Bool {
        client?.isRunning() ?? false
    }
#else
    func start(configJSON: String, sink: ProxyRuntime) -> String {
        return "Mobile.xcframework is not linked. Run ./build-ios.sh on macOS and add the framework to the app target."
    }

    func stop() {}

    func isRunning() -> Bool {
        return false
    }
#endif
}

#if canImport(Mobile)
private final class MobileCallback: NSObject, MobileIosCallbackProtocol {
    private weak var sink: ProxyRuntime?

    init(sink: ProxyRuntime) {
        self.sink = sink
    }

    func onLog(_ message: String?) {
        guard let message else { return }
        Task { @MainActor in
            self.sink?.receiveLog(message)
        }
    }

    func onStatus(_ status: String?) {
        guard let status else { return }
        Task { @MainActor in
            self.sink?.receiveStatus(status)
        }
    }
}
#endif
