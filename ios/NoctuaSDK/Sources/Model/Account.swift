import Foundation

struct Account: Encodable {
    let playerId: Int64
    let gameId: Int64
    let rawData: String
    let lastUpdated: Int64

    init(playerId: Int64, gameId: Int64, rawData: String, lastUpdated: Int64 = Int64(Date().timeIntervalSince1970 * 1000)) {
        self.playerId = playerId
        self.gameId = gameId
        self.rawData = rawData
        self.lastUpdated = lastUpdated
    }
}
