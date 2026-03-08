import Foundation

nonisolated struct ConfigGenerator: Sendable {
    private static let serviceID = "HEVpnj1BCmWLoddTkN9fSedR"
    static let selectedKeyIDStorageKey = "nordlynx_selected_key_id"
    static let customKeyStorageKey = "nordlynx_custom_key"
    static let customKeyNameStorageKey = "nordlynx_custom_key_name"

    static var selectedKeyID: String {
        UserDefaults.standard.string(forKey: selectedKeyIDStorageKey) ?? AccessKey.nick.id
    }

    static var activeAccessKey: AccessKey {
        let keyID = selectedKeyID
        if let preset = AccessKey.presets.first(where: { $0.id == keyID }) {
            return preset
        }
        if keyID == "custom" {
            let key = UserDefaults.standard.string(forKey: customKeyStorageKey) ?? ""
            let name = UserDefaults.standard.string(forKey: customKeyNameStorageKey) ?? "Custom"
            if !key.isEmpty {
                return AccessKey(id: "custom", name: name, key: key, isPreset: false)
            }
        }
        return .nick
    }

    static var activePrivateKey: String {
        activeAccessKey.key
    }

    static func selectKey(_ keyID: String) {
        UserDefaults.standard.set(keyID, forKey: selectedKeyIDStorageKey)
    }

    static func saveCustomKey(name: String, key: String) {
        let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else { return }
        UserDefaults.standard.set(trimmedKey, forKey: customKeyStorageKey)
        UserDefaults.standard.set(trimmedName.isEmpty ? "Custom" : trimmedName, forKey: customKeyNameStorageKey)
        UserDefaults.standard.set("custom", forKey: selectedKeyIDStorageKey)
    }

    static func removeCustomKey() {
        UserDefaults.standard.removeObject(forKey: customKeyStorageKey)
        UserDefaults.standard.removeObject(forKey: customKeyNameStorageKey)
        if selectedKeyID == "custom" {
            selectKey(AccessKey.nick.id)
        }
    }

    static var hasCustomKey: Bool {
        let key = UserDefaults.standard.string(forKey: customKeyStorageKey) ?? ""
        return !key.isEmpty
    }

    static var allAvailableKeys: [AccessKey] {
        var keys = AccessKey.presets
        if hasCustomKey {
            let key = UserDefaults.standard.string(forKey: customKeyStorageKey) ?? ""
            let name = UserDefaults.standard.string(forKey: customKeyNameStorageKey) ?? "Custom"
            keys.append(AccessKey(id: "custom", name: name, key: key, isPreset: false))
        }
        return keys
    }

    private let service = NordVPNService()

    func generate(from servers: [ServerResponse], vpnProtocol: VPNProtocol) async throws -> [GeneratedConfig] {
        switch vpnProtocol {
        case .wireguardUDP:
            return try generateWireGuard(from: servers)
        case .openvpnUDP, .openvpnTCP:
            return try await generateOpenVPN(from: servers, vpnProtocol: vpnProtocol)
        }
    }

    private func generateWireGuard(from servers: [ServerResponse]) throws -> [GeneratedConfig] {
        let privateKey = Self.activePrivateKey
        var configs: [GeneratedConfig] = []

        for server in servers {
            guard let publicKey = extractPublicKey(from: server, techIdentifier: "wireguard_udp") else {
                continue
            }

            let country = server.locations?.first?.country
            let countryName = country?.name ?? "Unknown"
            let countryCode = country?.code ?? ""
            let cityName = country?.city?.name ?? ""

            let content = """
            [Interface]
            PrivateKey = \(privateKey)
            Address = 10.5.0.2/32
            DNS = 103.86.96.100, 103.86.99.100

            [Peer]
            PublicKey = \(publicKey)
            Endpoint = \(server.station):51820
            AllowedIPs = 0.0.0.0/0, ::/0
            PersistentKeepalive = 25
            """

            configs.append(GeneratedConfig(
                hostname: server.hostname,
                stationIP: server.station,
                publicKey: publicKey,
                fileContent: content,
                fileName: "\(server.hostname).conf",
                countryName: countryName,
                countryCode: countryCode,
                cityName: cityName,
                serverLoad: server.load,
                vpnProtocol: .wireguardUDP,
                port: 51820
            ))
        }

        guard !configs.isEmpty else {
            throw NordVPNError.noServersFound
        }

        return configs
    }

    private func generateOpenVPN(from servers: [ServerResponse], vpnProtocol: VPNProtocol) async throws -> [GeneratedConfig] {
        var configs: [GeneratedConfig] = []

        try await withThrowingTaskGroup(of: GeneratedConfig?.self) { group in
            for server in servers {
                group.addTask {
                    let country = server.locations?.first?.country
                    let countryName = country?.name ?? "Unknown"
                    let countryCode = country?.code ?? ""
                    let cityName = country?.city?.name ?? ""

                    do {
                        let ovpnContent = try await service.downloadOVPNConfig(
                            hostname: server.hostname,
                            vpnProtocol: vpnProtocol
                        )

                        let suffix = vpnProtocol == .openvpnTCP ? "tcp" : "udp"
                        let fileName = "\(server.hostname).\(suffix).ovpn"

                        return GeneratedConfig(
                            hostname: server.hostname,
                            stationIP: server.station,
                            publicKey: "",
                            fileContent: ovpnContent,
                            fileName: fileName,
                            countryName: countryName,
                            countryCode: countryCode,
                            cityName: cityName,
                            serverLoad: server.load,
                            vpnProtocol: vpnProtocol,
                            port: vpnProtocol.defaultPort
                        )
                    } catch {
                        return nil
                    }
                }
            }

            for try await config in group {
                if let config {
                    configs.append(config)
                }
            }
        }

        configs.sort { $0.hostname < $1.hostname }

        guard !configs.isEmpty else {
            throw NordVPNError.noServersFound
        }

        return configs
    }

    func saveToDocuments(_ configs: [GeneratedConfig]) throws -> URL {
        let documentsURL = URL.documentsDirectory.appending(path: "NordLynx_Configs")

        if FileManager.default.fileExists(atPath: documentsURL.path()) {
            try FileManager.default.removeItem(at: documentsURL)
        }

        try FileManager.default.createDirectory(at: documentsURL, withIntermediateDirectories: true)

        for config in configs {
            let fileURL = documentsURL.appending(path: config.fileName)
            try config.fileContent.write(to: fileURL, atomically: true, encoding: .utf8)
        }

        return documentsURL
    }

    private func extractPublicKey(from server: ServerResponse, techIdentifier: String) -> String? {
        guard let tech = server.technologies.first(where: { $0.identifier == techIdentifier }),
              let metadata = tech.metadata,
              let keyMeta = metadata.first(where: { $0.name == "public_key" }) else {
            return nil
        }
        return keyMeta.value
    }

    var credentials: (serviceID: String, accessToken: String) {
        (Self.serviceID, Self.activePrivateKey)
    }
}
