import Foundation

nonisolated struct GeneratedConfig: Identifiable, Sendable {
    let id = UUID()
    let hostname: String
    let stationIP: String
    let publicKey: String
    let fileContent: String
    let fileName: String
    let countryName: String
    let countryCode: String
    let cityName: String
    let serverLoad: Int
    let vpnProtocol: VPNProtocol
    let port: Int
}
