import Foundation

nonisolated struct AccessKey: Identifiable, Sendable, Equatable, Hashable {
    let id: String
    let name: String
    let key: String
    let isPreset: Bool

    static let nick = AccessKey(
        id: "nick",
        name: "Nick",
        key: "e9f2abb927fb478e7c61afed90ee4cae8e3094b47418748ea7e518c955a0a0d1",
        isPreset: true
    )

    static let poli = AccessKey(
        id: "poli",
        name: "Poli",
        key: "e9f2ab075820d8ccc3362eadc4bbadb335571961002b5d5d606cbe4083680625",
        isPreset: true
    )

    static let presets: [AccessKey] = [.nick, .poli]
}
