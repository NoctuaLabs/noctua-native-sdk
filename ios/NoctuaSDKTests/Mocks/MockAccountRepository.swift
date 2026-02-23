import Foundation
@testable import NoctuaSDK

class MockAccountRepository: AccountRepositoryProtocol {
    var accounts: [Account] = []
    var putCalls: [Account] = []
    var deleteCalls: [(Int64, Int64)] = []

    func put(_ account: Account) {
        putCalls.append(account)
        accounts.removeAll { $0.gameId == account.gameId && $0.playerId == account.playerId }
        accounts.append(account)
    }

    func getAll() -> [Account] {
        return accounts
    }

    func getSingle(gameId: Int64, playerId: Int64) -> Account? {
        return accounts.first { $0.gameId == gameId && $0.playerId == playerId }
    }

    func getByPlayerId(playerId: Int64) -> [Account] {
        return accounts.filter { $0.playerId == playerId }
    }

    func delete(gameId: Int64, playerId: Int64) {
        deleteCalls.append((gameId, playerId))
        accounts.removeAll { $0.gameId == gameId && $0.playerId == playerId }
    }
}
