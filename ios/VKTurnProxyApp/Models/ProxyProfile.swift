import Foundation

struct ProxyProfile: Identifiable, Codable, Equatable {
    enum CaptchaSolver: String, Codable, CaseIterable, Identifiable {
        case v1
        case v2

        var id: String { rawValue }
    }

    var id: UUID
    var name: String
    var listen: String
    var vkLink: String
    var yandexLink: String
    var peerAddr: String
    var turnHost: String
    var turnPort: String
    var numStreams: Int
    var useUDP: Bool
    var noDTLS: Bool
    var vlessMode: Bool
    var vlessBond: Bool
    var wrapMode: Bool
    var wrapKeyHex: String
    var streamsPerCred: Int
    var debug: Bool
    var manualCaptcha: Bool
    var captchaSolver: CaptchaSolver
    var rawConfigJSON: String

    init(
        id: UUID = UUID(),
        name: String = "Local proxy",
        listen: String = "127.0.0.1:9000",
        vkLink: String = "",
        yandexLink: String = "",
        peerAddr: String = "",
        turnHost: String = "",
        turnPort: String = "",
        numStreams: Int = 10,
        useUDP: Bool = false,
        noDTLS: Bool = false,
        vlessMode: Bool = false,
        vlessBond: Bool = false,
        wrapMode: Bool = false,
        wrapKeyHex: String = "",
        streamsPerCred: Int = 0,
        debug: Bool = true,
        manualCaptcha: Bool = false,
        captchaSolver: CaptchaSolver = .v2,
        rawConfigJSON: String = ""
    ) {
        self.id = id
        self.name = name
        self.listen = listen
        self.vkLink = vkLink
        self.yandexLink = yandexLink
        self.peerAddr = peerAddr
        self.turnHost = turnHost
        self.turnPort = turnPort
        self.numStreams = numStreams
        self.useUDP = useUDP
        self.noDTLS = noDTLS
        self.vlessMode = vlessMode
        self.vlessBond = vlessBond
        self.wrapMode = wrapMode
        self.wrapKeyHex = wrapKeyHex
        self.streamsPerCred = streamsPerCred
        self.debug = debug
        self.manualCaptcha = manualCaptcha
        self.captchaSolver = captchaSolver
        self.rawConfigJSON = rawConfigJSON
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case listen
        case vkLink
        case yandexLink
        case peerAddr
        case turnHost
        case turnPort
        case numStreams
        case useUDP
        case noDTLS
        case vlessMode
        case vlessBond
        case wrapMode
        case wrapKeyHex
        case streamsPerCred
        case debug
        case manualCaptcha
        case captchaSolver
        case rawConfigJSON
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Local proxy"
        listen = try container.decodeIfPresent(String.self, forKey: .listen) ?? "127.0.0.1:9000"
        vkLink = try container.decodeIfPresent(String.self, forKey: .vkLink) ?? ""
        yandexLink = try container.decodeIfPresent(String.self, forKey: .yandexLink) ?? ""
        peerAddr = try container.decodeIfPresent(String.self, forKey: .peerAddr) ?? ""
        turnHost = try container.decodeIfPresent(String.self, forKey: .turnHost) ?? ""
        turnPort = try container.decodeIfPresent(String.self, forKey: .turnPort) ?? ""
        numStreams = try container.decodeIfPresent(Int.self, forKey: .numStreams) ?? 10
        useUDP = try container.decodeIfPresent(Bool.self, forKey: .useUDP) ?? false
        noDTLS = try container.decodeIfPresent(Bool.self, forKey: .noDTLS) ?? false
        vlessMode = try container.decodeIfPresent(Bool.self, forKey: .vlessMode) ?? false
        vlessBond = try container.decodeIfPresent(Bool.self, forKey: .vlessBond) ?? false
        wrapMode = try container.decodeIfPresent(Bool.self, forKey: .wrapMode) ?? false
        wrapKeyHex = try container.decodeIfPresent(String.self, forKey: .wrapKeyHex) ?? ""
        streamsPerCred = try container.decodeIfPresent(Int.self, forKey: .streamsPerCred) ?? 0
        debug = try container.decodeIfPresent(Bool.self, forKey: .debug) ?? true
        manualCaptcha = try container.decodeIfPresent(Bool.self, forKey: .manualCaptcha) ?? false
        captchaSolver = try container.decodeIfPresent(CaptchaSolver.self, forKey: .captchaSolver) ?? .v2
        rawConfigJSON = try container.decodeIfPresent(String.self, forKey: .rawConfigJSON) ?? ""
    }

    var linkSummary: String {
        if !vkLink.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "VK Calls"
        }
        if !yandexLink.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Yandex Telemost"
        }
        return "No call link"
    }

    var hasRawConfig: Bool {
        !rawConfigJSON.trimmed.isEmpty
    }

    var canStart: Bool {
        if hasRawConfig {
            return true
        }
        let hasVK = !vkLink.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasYandex = !yandexLink.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return !listen.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !peerAddr.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && hasVK != hasYandex
    }

    func configJSONString(encoder: JSONEncoder = JSONEncoder()) throws -> String {
        if hasRawConfig {
            let raw = rawConfigJSON.trimmed
            let data = Data(raw.utf8)
            let object = try JSONSerialization.jsonObject(with: data)
            guard JSONSerialization.isValidJSONObject(object) else {
                throw ProfileValidationError.invalidRawConfig
            }
            return raw
        }

        let data = try encoder.encode(clientConfig())
        guard let configJSON = String(data: data, encoding: .utf8) else {
            throw ProfileValidationError.encodingFailed
        }
        return configJSON
    }

    func clientConfig() -> ClientConfig {
        ClientConfig(
            turnHost: turnHost.trimmed,
            turnPort: turnPort.trimmed,
            listen: listen.trimmed,
            vkLink: vkLink.trimmed,
            yandexLink: yandexLink.trimmed,
            peerAddr: peerAddr.trimmed,
            numStreams: numStreams,
            useUDP: useUDP,
            noDTLS: noDTLS,
            vlessMode: vlessMode,
            vlessBond: vlessBond,
            wrapMode: wrapMode,
            wrapKeyHex: wrapKeyHex.trimmed,
            streamsPerCred: streamsPerCred,
            debug: debug,
            manualCaptcha: manualCaptcha,
            captchaSolver: captchaSolver.rawValue
        )
    }
}

enum ProfileValidationError: LocalizedError {
    case encodingFailed
    case invalidRawConfig

    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode profile."
        case .invalidRawConfig:
            return "Advanced config must be a valid JSON object."
        }
    }
}

struct ClientConfig: Codable {
    var turnHost: String
    var turnPort: String
    var listen: String
    var vkLink: String
    var yandexLink: String
    var peerAddr: String
    var numStreams: Int
    var useUDP: Bool
    var noDTLS: Bool
    var vlessMode: Bool
    var vlessBond: Bool
    var wrapMode: Bool
    var wrapKeyHex: String
    var streamsPerCred: Int
    var debug: Bool
    var manualCaptcha: Bool
    var captchaSolver: String

    enum CodingKeys: String, CodingKey {
        case turnHost = "turn_host"
        case turnPort = "turn_port"
        case listen
        case vkLink = "vk_link"
        case yandexLink = "yandex_link"
        case peerAddr = "peer_addr"
        case numStreams = "num_streams"
        case useUDP = "use_udp"
        case noDTLS = "no_dtls"
        case vlessMode = "vless_mode"
        case vlessBond = "vless_bond"
        case wrapMode = "wrap_mode"
        case wrapKeyHex = "wrap_key_hex"
        case streamsPerCred = "streams_per_cred"
        case debug
        case manualCaptcha = "manual_captcha"
        case captchaSolver = "captcha_solver"
    }
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
