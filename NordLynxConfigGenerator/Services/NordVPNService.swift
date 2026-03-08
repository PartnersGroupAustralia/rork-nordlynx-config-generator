import Foundation

nonisolated enum NordVPNError: Error, LocalizedError, Sendable {
    case invalidURL
    case networkError(Int)
    case connectionFailed(String)
    case decodingError(String)
    case noServersFound
    case noPublicKey(String)
    case timeout
    case ovpnDownloadFailed(String)
    case allRetriesFailed(Int)
    case rateLimited

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "Invalid API URL."
        case .networkError(let statusCode):
            "Server returned HTTP \(statusCode). Try again later."
        case .connectionFailed(let reason):
            "Connection failed: \(reason)"
        case .decodingError(let detail):
            "Failed to parse server data: \(detail)"
        case .noServersFound:
            "No servers returned. Try fewer configs or a different filter."
        case .noPublicKey(let hostname):
            "No WireGuard key found for \(hostname)."
        case .timeout:
            "Request timed out. Check your connection."
        case .ovpnDownloadFailed(let hostname):
            "Failed to download OpenVPN config for \(hostname)."
        case .allRetriesFailed(let attempts):
            "All \(attempts) retry attempts failed. Check your connection."
        case .rateLimited:
            "Rate limited by NordVPN API. Please wait and try again."
        }
    }
}

nonisolated struct NordVPNService: Sendable {
    private static let baseURL = "https://api.nordvpn.com/v1/servers/recommendations"
    private static let countriesURL = "https://api.nordvpn.com/v1/servers/countries"
    private static let ovpnBaseURL = "https://downloads.nordcdn.com/configs/files"

    private static let maxRetries = 3
    private static let retryBaseDelay: TimeInterval = 1.0

    private var session: URLSession {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 20
        config.timeoutIntervalForResource = 45
        config.waitsForConnectivity = true
        config.httpMaximumConnectionsPerHost = 6
        return URLSession(configuration: config)
    }

    func fetchCountries() async throws -> [CountryResponse] {
        guard let url = URL(string: Self.countriesURL) else {
            throw NordVPNError.invalidURL
        }

        let data = try await performRequestWithRetry(url: url)

        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            var countries = try decoder.decode([CountryResponse].self, from: data)
            countries.sort { $0.name < $1.name }
            return countries
        } catch let error as DecodingError {
            throw NordVPNError.decodingError(decodingDetail(error))
        }
    }

    func fetchServers(limit: Int, countryId: Int? = nil, vpnProtocol: VPNProtocol = .wireguardUDP) async throws -> [ServerResponse] {
        var urlString = "\(Self.baseURL)?limit=\(limit)&filters[servers_technologies][identifier]=\(vpnProtocol.rawValue)"
        if let countryId {
            urlString += "&filters[country_id]=\(countryId)"
        }

        guard let url = URL(string: urlString) else {
            throw NordVPNError.invalidURL
        }

        let data = try await performRequestWithRetry(url: url)

        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode([ServerResponse].self, from: data)
        } catch let error as DecodingError {
            throw NordVPNError.decodingError(decodingDetail(error))
        }
    }

    func downloadOVPNConfig(hostname: String, vpnProtocol: VPNProtocol) async throws -> String {
        let suffix = vpnProtocol == .openvpnTCP ? "tcp" : "udp"
        let urlString = "\(Self.ovpnBaseURL)/\(vpnProtocol.ovpnConfigPath)/servers/\(hostname).\(suffix).ovpn"

        guard let url = URL(string: urlString) else {
            throw NordVPNError.invalidURL
        }

        let data = try await performRequestWithRetry(url: url)

        guard let content = String(data: data, encoding: .utf8), !content.isEmpty else {
            throw NordVPNError.ovpnDownloadFailed(hostname)
        }

        return content
    }

    private func performRequestWithRetry(url: URL) async throws -> Data {
        var lastError: (any Error)?

        for attempt in 0..<Self.maxRetries {
            do {
                let (data, response) = try await performRequest(url: url)
                try validateResponse(response)
                return data
            } catch let error as NordVPNError where isRetryable(error) {
                lastError = error
                if attempt < Self.maxRetries - 1 {
                    let delay = Self.retryBaseDelay * pow(2.0, Double(attempt))
                    let jitter = Double.random(in: 0...0.5)
                    try await Task.sleep(for: .seconds(delay + jitter))
                }
            } catch {
                throw error
            }
        }

        if let lastError {
            throw lastError
        }
        throw NordVPNError.allRetriesFailed(Self.maxRetries)
    }

    private func isRetryable(_ error: NordVPNError) -> Bool {
        switch error {
        case .timeout, .connectionFailed, .rateLimited:
            true
        case .networkError(let code):
            code == 429 || code >= 500
        default:
            false
        }
    }

    private func performRequest(url: URL) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(from: url)
        } catch let error as URLError where error.code == .timedOut {
            throw NordVPNError.timeout
        } catch let error as URLError where error.code == .notConnectedToInternet || error.code == .networkConnectionLost {
            throw NordVPNError.connectionFailed("No internet connection.")
        } catch let error as URLError {
            throw NordVPNError.connectionFailed(error.localizedDescription)
        }
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NordVPNError.connectionFailed("Invalid response type.")
        }
        if httpResponse.statusCode == 429 {
            throw NordVPNError.rateLimited
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NordVPNError.networkError(httpResponse.statusCode)
        }
    }

    private func decodingDetail(_ error: DecodingError) -> String {
        switch error {
        case .keyNotFound(let key, _):
            "Missing key: \(key.stringValue)"
        case .typeMismatch(let type, let context):
            "Type mismatch for \(type) at \(context.codingPath.map(\.stringValue).joined(separator: "."))"
        default:
            error.localizedDescription
        }
    }
}
